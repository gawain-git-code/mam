import socket, numpy as np
import os, sys, time
import threading

def on_new_client(connection, addr):
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
    connection.close()

def main():

    print('Server started!')
    ServerSideSocket = socket.socket()
    host = '127.0.0.1'
    port = 9090
    thread_list = []

    try:
        ServerSideSocket.bind((host, port))
    except socket.error as e:
        print(str(e))

    print('Socket is listening..')
    ServerSideSocket.listen(5)

    try:
        while True:
            print('Waiting for clients...')
            Client, address = ServerSideSocket.accept()
            print('Connected to: ' + address[0] + ':' + str(address[1]))
            print('Alive threads: ', str(threading.active_count()))
            x = threading.Thread(target=on_new_client, args=(Client, address))
            print("Main    : before running thread")
            x.start()
            print("Main    : wait for the thread to finish")
    except KeyboardInterrupt:
        print('interrupted!')
        x.join()
        print("Main    : all done")

    ServerSideSocket.close()

if __name__ == '__main__':
    main()