from concurrent.futures import process
from ctypes import addressof
import socket, numpy as np
import os, sys, time

import multiprocessing
from multiprocessing import Manager
import threading

from sqlalchemy import false

from lib.account_class import MT5Account

print(sys.version)

def mt5_client_process(connection, addr, stop_event):
    while True:
        cummdata = ''
        cmd = "CMD_FETCH_ACC_INFO"
        connection.send(bytes(str(cmd), "utf-8"))
        data = connection.recv(2048)
        cummdata+=data.decode("utf-8")
        if not data:
            break
        print(cummdata)
        time.sleep(2)

        if stop_event.is_set():
            print("Kill signal received in ", multiprocessing.current_process())
            break
    # close client connection on exit
    connection.close()

def client_server(sock_queue, incoming_event, stop_event):

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
        print('Waiting for clients...')
        client, address = ServerSideSocket.accept()
        print('Connected to: ' + address[0] + ':' + str(address[1]))
        # pass connection to queue and notify process_manager
        c = (client, address)
        sock_queue.put(c)
        incoming_event.set()
        # Start new process for incoming client
        # new_process = multiprocessing.Process(target=mt5_client_process, 
        #                 args=(client, address, stop_event))
        # new_process.start()
        # process_list.append(new_process)
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
    cummdata = ''
    try:
        data = connection.recv(2048)
        cummdata+=data.decode("utf-8")
        if not data:
            return
        return cummdata
    except:
        connection.close()
        print("Read from connection {} raised exception.".format(connection))

def mt5_exec_cmd(account: MT5Account):
    if account.command == '':
        print("Error: Empty command!")
        return False
    # acuqire the lock
    with account.lock:
        # send cmd
        send_to_connection(account.sock, account.command)
        # read back
        try:
            data_received = ''
            while True:
                data_received = data_received + account.sock.recv(500000).decode()
                print(data_received)
                if data_received.endswith('!'):
                    break
            # exec callback to update
            account.callback(data_received)
            account.command_OK = True
            account.connected = True
        except socket.timeout as msg:
            account.timeout = True
            account.command_return_error = 'Unexpected socket communication error'
            print(msg)
            account.command_OK = False
            account.connected = False
        except:
            account.command_OK = False
            account.connected = False
            account.sock.close()
            print("Read from connection {} raised exception.".format(account.login)) 


def process_manager():

    print("Start Process Manager ...")
    multiprocessing.set_start_method('spawn')

    manager = Manager()
    client_sock_queue = multiprocessing.Queue()
    stop_event = multiprocessing.Event()
    incoming_event = multiprocessing.Event()

    # process_list = []
    # print(type(process_list))

    client_server_process = multiprocessing.Process(target=client_server, 
                            args=(client_sock_queue, incoming_event, stop_event))
    #process_list.append(client_server_process)
    client_server_process.start()
    account_book = {}
    account_book_lock = threading.Lock()
    while True:
        try:
            # check for incoming new client
            while not client_sock_queue.empty():
                new_socket = client_sock_queue.get()
                (client, address) = new_socket
                print("client: {}, address {}".format(client, address))
                # Try to create a MT5 account
                new_account = MT5Account(client)
                #new_account.update_account_info()
                new_account.command = "CMD_FETCH_ACC_INFO"
                new_account.callback = new_account.update_account_info_callback
                mt5_exec_cmd(new_account)
                # check if the account login is 0, remove it and continue
                if new_account.login == 0:
                    del new_account
                    continue
                # check if the new account already exist with the same login
                if new_account.login in account_book.keys():
                    print("Account {} already exist.".format(new_account.login))
                with account_book_lock:
                    account_book[new_account.login] = new_account
                print("New Account {} registered.".format(new_account.login))

            #check all processes are alive
            time.sleep(2)
            #print("I am alive.")
            for login in list(account_book):
                acc = account_book[login]
                if not acc.connected:
                    print("Found a zombie account ", login)
                    # remove it
                    with account_book_lock:
                        account_book.pop(acc.login)
                        continue
                acc.command = "CMD_FETCH_ACC_INFO"
                acc.callback = acc.update_account_info_callback
                #mt5_exec_cmd(acc)
                x = threading.Thread(target=mt5_exec_cmd, args=[acc])
                x.start()

        except KeyboardInterrupt:
            print("process_manager Interrupted.")
            stop_event.set()
            # for p in process_list:
            #     p.terminate()
            #     p.join()
            sys.exit(0)
    
        
if __name__ == '__main__':
    process_manager()