
import os, sys
from datetime import datetime
import socket, multiprocessing
import threading
from threading import Lock

import socket
import numpy as np
import pandas as pd
from datetime import datetime
import pytz
import io

TZ_SERVER = 'Europe/Tallinn' # EET
TZ_LOCAL  = 'Europe/Budapest'
TZ_UTC    = 'UTC'

ERROR_DICT = {}
ERROR_DICT['00001'] = 'Undefined check connection error'

ERROR_DICT['00101'] = 'IP address error'
ERROR_DICT['00102'] = 'Port number error'
ERROR_DICT['00103'] = 'Connection error with license EA'
ERROR_DICT['00104'] = 'Undefined answer from license EA'

ERROR_DICT['00301'] = 'Unknown instrument for broker'
ERROR_DICT['00302'] = 'Instrument not in demo'

ERROR_DICT['00401'] = 'Instrument not in demo'
ERROR_DICT['00402'] = 'Instrument not exists for broker'

ERROR_DICT['00501'] = 'No instrument defined/configured'

ERROR_DICT['02001'] = 'Instrument not in demo'
ERROR_DICT['02002'] = 'No valid instrument'

ERROR_DICT['02101'] = 'Instrument not in demo'
ERROR_DICT['02102'] = 'No ticks'
ERROR_DICT['02103'] = 'Not imlemented in MT4'

ERROR_DICT['04101'] = 'Instrument not in demo'
ERROR_DICT['04102'] = 'Wrong/unknown time frame'
ERROR_DICT['04103'] = 'No records'
ERROR_DICT['04104'] = 'Undefined error'


ERROR_DICT['04201'] = 'Instrument not in demo'
ERROR_DICT['04202'] = 'Wrong/unknown time frame'
ERROR_DICT['04203'] = 'No records' 

ERROR_DICT['04501'] = 'Instrument not in demo'
ERROR_DICT['04502'] = 'Wrong/unknown time frame'
ERROR_DICT['04503'] = 'No records'
ERROR_DICT['04504'] = 'Missing market instrument'

ERROR_DICT['06201'] = 'Wrong time window'
ERROR_DICT['06401'] = 'Wrong time window'

ERROR_DICT['07001'] = 'Trading not allowed, check MT terminal settings' 
ERROR_DICT['07002'] = 'Instrument not in demo' 
ERROR_DICT['07003'] = 'Instrument not in market watch' 
ERROR_DICT['07004'] = 'Instrument not known for broker'
ERROR_DICT['07005'] = 'Unknown order type' 
ERROR_DICT['07006'] = 'Wrong SL value' 
ERROR_DICT['07007'] = 'Wrong TP value'
ERROR_DICT['07008'] = 'Wrong volume value'
ERROR_DICT['07009'] = 'Error opening market order'
ERROR_DICT['07010'] = 'Error opening pending order'

ERROR_DICT['07101'] = 'Trading not allowed'
ERROR_DICT['07102'] = 'Position not found/error'

ERROR_DICT['07201'] = 'Trading not allowed'
ERROR_DICT['07202'] = 'Position not found/error'
ERROR_DICT['07203'] = 'Wrong volume'
ERROR_DICT['07204'] = 'Error in partial close'

ERROR_DICT['07301'] = 'Trading not allowed'
ERROR_DICT['07302'] = 'Error in delete'

ERROR_DICT['07501'] = 'Trading not allowed'
ERROR_DICT['07502'] = 'Position not open' 
ERROR_DICT['07503'] = 'Error in modify'

ERROR_DICT['07601'] = 'Trading not allowed'
ERROR_DICT['07602'] = 'Position not open' 
ERROR_DICT['07603'] = 'Error in modify'

ERROR_DICT['07701'] = 'Trading not allowed'
ERROR_DICT['07702'] = 'Position not open' 
ERROR_DICT['07703'] = 'Error in modify'

ERROR_DICT['07801'] = 'Trading not allowed'
ERROR_DICT['07802'] = 'Position not open' 
ERROR_DICT['07803'] = 'Error in modify' 

ERROR_DICT['99901'] = 'Undefined error'


class MT5Account:
    def __init__(self, login: int, socket = None):
        self.login = login
        self.sock = socket
        #
        self.socket_error: int = 0
        self.socket_error_message: str = ''
        self.order_return_message: str = ''
        self.order_error: int = 0
        self.connected: bool = False
        self.timeout: bool = False
        self.command_OK: bool = False
        self.command_return_error: str = ''
        self.debug: bool = False
        self.version: str = '2_07'
        self.max_bars: int = 5000
        self.max_ticks: int = 5000
        self.timeout_value: int = 60
        self.instrument_conversion_list: dict = {}
        self.instrument_name_broker: str = ''
        self.instrument_name_universal: str = ''
        self.date_from: datetime = '2000/01/01, 00:00:00'
        self.date_to: datetime = datetime.now()
        self.instrument: str = ''
        #
        self.account_name: str = ''

        self.trade_mode: str = ''
        self.company: str = ''
        self.server: str = ''

        self.lock = None
        self.callback = None
        self.command: str = ''
        self.queue = None
        self.event = None

    @property
    def IsConnected(self) -> bool:
        """Returns connection status.
        Returns:
            bool: True or False
        """
        return self.connected

    def update_account_info(self):
        with self.lock:
            self.command = "F001^0^"
            self.callback = self.update_account_info_callback

    def update_account_info_callback(self, dataString):
        x = dataString.split('^')
        if self.debug:
            print(x)
        x.pop(-1)
        if str(x[0]) != 'F001':
            self.command_return_error = ERROR_DICT['99901']
            self.command_OK = False
            return False

        self.account_name = str(x[1])
        self.login = int(x[2])
        self.trade_mode = str(x[3])
        self.company = str(x[4])
        self.server = str(x[5])
        self.command_OK = True

        return True

    def Get_static_account_info(self) -> dict:
        """
        Retrieves static account information.

        Returns: Dictionary with:
            Account name,
            Account number,
            Account currency,
            Account type,
            Account leverage,
            Account trading allowed,
            Account maximum number of pending orders,
            Account margin call percentage,
            Account close open trades margin percentage
        """
        self.command_return_error = ''

        ok, dataString = self.send_command('F001^0^')
        if (ok == False):
            self.command_OK = False
            return None

        if self.debug:
            print(dataString)

        x = dataString.split('^')
        if x[0] != 'F001':
            self.command_return_error = ERROR_DICT['99901']
            self.command_OK = False
            return None

        returnDict = {}
        del x[0:2]
        x.pop(-1)

        returnDict['name'] = str(x[0])
        returnDict['login'] = str(x[1])
        returnDict['currency'] = str(x[2])
        returnDict['type'] = str(x[3])
        returnDict['leverage'] = int(x[4])
        returnDict['trade_allowed'] = bool(x[5])
        returnDict['limit_orders'] = int(x[6])
        returnDict['margin_call'] = float(x[7])
        returnDict['margin_close'] = float(x[8])

        self.command_OK = True
        return returnDict


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


def mt5_exec_cmd(account: MT5Account, locked_on_ops=True):
    if account.command == '':
        print("Error: Empty command!")
        return False
    
    # acuqire the lock
    if locked_on_ops == True and account.lock != None:
        if account.lock != None:
            account.lock.acquire()
        else:
            raise Exception("Require lock but lock is missing!")

    # STEP1: send cmd
    try:
        account.sock.send(bytes(str(account.command), "utf-8"))
    except:
        # broken socket connection
        account.connected = False
        account.sock.close()
        account.command_return_error = "Send to sock raised exception."

    # STEP2: read response
    try:
        data_received = ''
        while True:
            data_received = data_received + account.sock.recv(500000).decode()
            if account.debug:
                print(data_received)
            if data_received.endswith('!'):
                break
        # exec callback to update
        account.callback(data_received)
        account.connected = True
    except socket.timeout as msg:
        account.timeout = True
        account.command_return_error = 'Unexpected socket communication error'
        print(msg)
        account.connected = False
        account.sock.close()
    except:
        account.connected = False
        account.command_return_error = "Read from sock raised exception."
        account.sock.close()

    if locked_on_ops == True:
        account.lock.release()