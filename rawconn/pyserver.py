from concurrent.futures import process
from ctypes import addressof
from distutils.log import ERROR
import socket, numpy as np
from ssl import enum_certificates
import os, sys, time

import multiprocessing
from multiprocessing import Manager
import threading
from prometheus_client import Enum

from sqlalchemy import false

from lib.account_class import *

print(sys.version)
print("Running ", multiprocessing.current_process())


def client_server(sock_queue, notice_queue, incoming_event, stop_event):

    print('Server started!')
    ServerSideSocket = socket.socket()
    host = '127.0.0.1'
    port = 9090
    max_num_clients = 1
    try:
        ServerSideSocket.bind((host, port))
    except socket.error as e:
        print(str(e))
    
    print('Socket is listening..')
    ServerSideSocket.listen(max_num_clients)
    
    while True:
        #print('Waiting for clients...')
        sock, address = ServerSideSocket.accept()
        #print('Connected to: ' + address[0] + ':' + str(address[1]))
        data = read_from_connection(sock)
        if not data:
            print("Read nothing from incoming client connection! ")
            sock.close()
        elif data.endswith('!'):
            # valid data end with '!'
            msg = data.split('#')
            msg.pop(-1)
            sock_type = msg[0]
            client_id = int(msg[1])
            if sock_type == 'S001':
                # print("This is a client connection.")
                # pass connection to queue and notify process_manager
                c = (client_id, sock, address)
                sock_queue.put(c)
                incoming_event.set()

            elif sock_type == 'S002':
                #print("This is a notifier connection.")
                # incoming message intact, reply with OK
                send_to_connection(sock, "OK")
                # pass incoming message and close connection
                notice_queue.put(msg)
                sock.close()
        else:
            # received invalid data, close connection directly!
            sock.close()

        if stop_event.is_set():
            print("Kill signal received in ", multiprocessing.current_process())
            break
    ServerSideSocket.close()

def send_to_connection(connection, cmd):
    try:
        connection.send(bytes(str(cmd), "utf-8"))
    except:
        # broken socket connection may be, chat client pressed ctrl+c for example
        connection.close()
        print("Send to connection {} raised exception.".format(connection))

def read_from_connection(connection):
    try:
        data = connection.recv(1024).decode()
        if not data:
            return
        return data
    except:
        connection.close()
        print("Read from connection {} raised exception.".format(connection))

# check for incoming connection queue and create new account
def process_new_account(incoming_sock, account_queue, stop_event, period_secs=1):
    while True:
        while not incoming_sock.empty():
            (client_id, sock, address) = incoming_sock.get()
            print("client: {}, address {}".format(client_id, address))
            # Try to create a MT5 account
            # new_account.command = "CMD_FETCH_ACC_INFO"
            # new_account.callback = new_account.update_account_info_callback
            # mt5_exec_cmd(new_account, false)
            # check if the account login is 0, remove it and continue
            if client_id == 0:
                print("Invalid account.")
                continue
            new_account = MT5Account(client_id, sock)
            new_account.connected = True
            # put the new acount onto queue
            account_queue.put(new_account)
        time.sleep(period_secs)
        if stop_event.is_set():
            print("Kill signal received in ", multiprocessing.current_process())
            break

account_book = {}
account_book_lock = threading.Lock()

class Account_Periodic_Print(threading.Thread):
    def __init__(self, event):
        threading.Thread.__init__(self)
        self.stopped = event

    def account_print(self):
        print(time.ctime())
        for login in list(account_book):
            acc = account_book[login]
            print(acc.__dict__)

    def run(self):
        while not self.stopped.wait(10):
            self.account_print()
    

def process_manager():
    print("Start Process Manager ...")
    multiprocessing.set_start_method('spawn')

    manager = Manager()
    client_sock_queue = manager.Queue()
    incoming_account = manager.Queue()
    #incoming_sock = manager.Queue()
    notification = manager.Queue()
    stop_event = multiprocessing.Event()
    incoming_event = multiprocessing.Event()

    accept_connection = multiprocessing.Process(target=client_server, 
                            args=(client_sock_queue, notification,
                            incoming_event, stop_event))
    #process_list.append(accept_connection)
    accept_connection.start()

    incoming_account_process = multiprocessing.Process(target=process_new_account, 
                            args=(client_sock_queue, incoming_account, stop_event))
    incoming_account_process.start()

    p_thread = Account_Periodic_Print(stop_event)
    p_thread.start()

    while True:
        try:
            # check for incoming notification
            while not notification.empty():
                msg = notification.get()
                print("Get notification from {}".format(msg[1]))
                # do something

            # check for incoming new client
            while not incoming_account.empty():
                new_account = incoming_account.get()
                new_account.lock = threading.Lock()
                login = new_account.login
                # check if the new account already exist with the same login
                if login in account_book.keys():
                    # account existed. update the incoming sock and addr
                    print("Account {} already exist.".format(login))
                    existing_account = account_book[login]
                    with existing_account.lock:
                        existing_account.sock = new_account.sock
                        existing_account.connected = True
                    del new_account
                else:   
                    with account_book_lock:
                        account_book[new_account.login] = new_account
                        print("New Account {} registered.".format(new_account.login))

            #check all processes are alive
            time.sleep(1)
            #print("I am alive.")
            thread_list = []
            for login in list(account_book):
                acc = account_book[login]

                if acc.sock.fileno() < 0:
                    print("Warning: socket is closed.", login)
                    print(acc.command_return_error)
                #if not acc.connected:
                    print("Found a zombie account ", login)
                    # remove it
                    with account_book_lock:
                        print(list(account_book))
                        account_book.pop(acc.login)
                        print(list(account_book))
                        del acc
                    continue

                if acc.lock.locked() == False:
                    acc.update_account_info()
                    x = threading.Thread(target=mt5_exec_cmd, args=[acc, True])
                    x.start()
                    thread_list.append(x)

                # error checking here

        except KeyboardInterrupt:
            print("process_manager Interrupted.")
            # this will stop the timer
            stop_event.set()
            incoming_account_process.terminate()
            accept_connection.terminate()
            print("Number of thread in list: ", threading.active_count())
            for x in thread_list:
                x.join()
            p_thread.join()
            print("Process Manager Exist.")
            sys.exit(0)
    
        
if __name__ == '__main__':
    process_manager()