import socket, numpy as np
import os, sys, time
import threading

from sklearn.linear_model import LinearRegression


class socketserver:
    def __init__(self, address = '', port = 9090):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address
        self.port = port
        self.sock.bind((self.address, self.port))
        self.cummdata = ''

    def listen(self):
        self.sock.listen(10)

    def accept(self):
        self.conn, self.addr = self.sock.accept()
        print('connected to', self.addr)

    def recvmsg(self):
        self.cummdata = ''
        while True:
            data = self.conn.recv(10000)
            self.cummdata+=data.decode("utf-8")
            if not data:
                break
            return self.cummdata

    def sendcmd(self, cmd):
        self.cummdata = ''
        self.conn.send(bytes(str(cmd), "utf-8"))
        return self.cummdata

    def __del__(self):
        self.sock.close()

def on_new_client(clientsocket,addr):
    while True:
        msg = serv.sendcmd(cmd="CMD_FETCH_ACC_INFO")
        data = serv.recvmsg()
        print(data)
        time.sleep(2)

if __name__ == "__main__":
    print('Server started!')
    serv = socketserver('127.0.0.1', 9090)
    serv.listen()
    try:
        while True:
            print('Waiting for clients...')
            serv.accept()
            print('Got connection from', serv.addr)
            x = threading.Thread(target=on_new_client, args=(serv.conn, serv.addr))
            print("Main    : before running thread")
            x.start()
            print("Main    : wait for the thread to finish")

    except KeyboardInterrupt:
        print('interrupted!')
        x.join()
        print("Main    : all done") 