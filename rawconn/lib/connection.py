from ctypes import addressof
import os, sys
from datetime import datetime
import socket
from datetime import datetime
from sqlalchemy import true

class connection:
    def __init__(self, id: int, socket, address):
        if id == 0:
            print("connection_init: Account ID invalid!")
            return None     
        if socket.fileno() < 0:
            print("connection_init: socket invalid!")
            return None
        self.sock = socket
        self.addr = address
        self.id = id
        self.lock = None
        # internal book keeping
        self.socket_error: int = 0
        self.socket_error_message: str = ''
        self.order_return_message: str = ''
        self.order_error: int = 0
        self.connected: bool = False
        self.timeout: bool = False
        self.debug: bool = False
        
    def __del__(self):
        self.sock.close()
        print("connection deleted {}: {}".format(self.id, self.addr))

    @property
    def IsConnected(self) -> bool:
        """Returns connection status.
        Returns:
            bool: True or False
        """
        return self.connected

    def Set_timeout(self,
                    timeout_in_seconds: int = 60
                    ):
        """
        Set time out value for socket communication with MT4 or MT5 EA/Bot.

        Args:
            timeout_in_seconds: the time out value
        Returns:
            None
        """
        self.timeout_value = timeout_in_seconds
        self.sock.settimeout(self.timeout_value)
        self.sock.setblocking(1)
        return

    def execute_cmd(self, command):
        
        if command == '':
            raise Exception("Error: Empty command!")

        # STEP1: send cmd
        try:
            self.sock.send(bytes(str(command), "utf-8"))
        except:
            # broken socket connection
            self.connected = False
            self.sock.close()
            self.command_return_error = "Send to sock raised exception."
            return False, None

        # STEP2: read response
        try:
            data_received = ''
            while True:
                data_received = data_received + self.sock.recv(500000).decode()
                if self.debug:
                    print(data_received)
                if data_received.endswith('!'):
                    break
            self.connected = True
            return True, data_received
        except socket.timeout as msg:
            self.timeout = True
            self.command_return_error = 'Unexpected socket communication error'
            print(msg)
            self.connected = False
            self.sock.close()
        except:
            self.connected = False
            self.command_return_error = "Read from sock raised exception."
            self.sock.close()

        return False, None

    def send_command(self,
                     command):
        #self.command = command + "!"
        self.command = command
        self.timeout = False
        #print(self.command)
        #print(self.socket)
        self.sock.send(bytes(self.command, "utf-8"))
        try:
            data_received = ''
            while True:
                data_received = data_received + self.sock.recv(500000).decode()
                print(data_received)
                if data_received.endswith('!'):
                    break
            return True, data_received
        except socket.timeout as msg:
            self.timeout = True
            self.command_return_error = 'Unexpected socket communication error'
            print(msg)
            return False, None