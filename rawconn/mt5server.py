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

from lib.account import MT5Account
from lib.connection import connection

print(sys.version)
print("Running ", multiprocessing.current_process())

account_book = {}
account_book_lock = threading.Lock()


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
                c = connection(client_id, sock, address)
                if (c):
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



class Account_Periodic_Print(threading.Thread):
    def __init__(self, event):
        threading.Thread.__init__(self)
        self.stopped = event

    def account_print(self):
        print(time.ctime())
        for id in list(account_book):
            acc = account_book[id]
            print(acc.__dict__)

    def run(self):
        while not self.stopped.wait(10):
            self.account_print()
    

def process_manager():
    print("Start Process Manager ...")
    multiprocessing.set_start_method('spawn')

    manager = Manager()
    account_sock_queue = manager.Queue()
    #incoming_account = manager.Queue()
    #incoming_sock = manager.Queue()
    notification = manager.Queue()
    stop_event = multiprocessing.Event()
    incoming_event = multiprocessing.Event()

    accept_connection = multiprocessing.Process(target=client_server, 
                            args=(account_sock_queue, notification,
                            incoming_event, stop_event))
    #process_list.append(accept_connection)
    accept_connection.start()

    p_thread = Account_Periodic_Print(stop_event)
    p_thread.start()

    while True:
        try:
            # check for incoming notification
            while not notification.empty():
                msg = notification.get()
                #print("Get notification from {}".format(msg[1]))
                # do something

            while not account_sock_queue.empty():
                new_conn = account_sock_queue.get()
                print("client: {}, address {}".format(new_conn.id, new_conn.addr))
                # check if the account login is 0, remove it and continue
                if new_conn.id == 0:
                    print("Invalid account.")
                    del new_conn
                    continue
                # assign lock to connection
                new_conn.lock = threading.Lock()
                # check if the new connection linked to existing account
                if new_conn.id in account_book.keys():
                    # account existed. update the incoming connection
                    print("Account {} already exist.".format(new_conn.id))
                    acc = account_book[new_conn.id]
                    with acc.lock:
                        acc.conn = new_conn
                        acc.connected = True
                else:
                    acc = MT5Account(new_conn.id, new_conn)
                    acc.lock = threading.Lock()
                    acc.connected = True
                    with account_book_lock:
                        account_book[acc.id] = acc
                        print("New Account {} registered.".format(acc.id))

            #check all processes are alive
            time.sleep(2)
            #print("I am alive.")
            thread_list = []
            zombie_account = []
            for id in list(account_book):
                acc = account_book[id]

                if acc.conn.sock.fileno() < 0:
                    print("Warning: socket is closed.", id)
                    print(acc.command_return_error)
                #if not acc.connected:
                    print("Found a zombie account ", id)
                    # remove it
                    with account_book_lock:
                        print(list(account_book))
                        account_book.pop(acc.id)
                        print(list(account_book))
                        zombie_account.append(acc)
                    continue

                #if acc.lock.locked() == False:
                    #x = threading.Thread(target=acc.Get_static_account_info)
                    #x.start()
                    #thread_list.append(x)

                if acc.lock.locked() == False:
                    acc.Get_static_account_info()
                    returnList = acc.Get_instruments()
                    print(returnList)

            # error checking here
            for x in zombie_account:
                del x

        except KeyboardInterrupt:
            print("process_manager Interrupted.")
            # this will stop the timer
            stop_event.set()
            accept_connection.terminate()
            print("Number of thread in list: ", threading.active_count())
            for x in thread_list:
                x.join()
            p_thread.join()
            print("Process Manager Exist.")
            sys.exit(0)
    
        
if __name__ == '__main__':
    process_manager()