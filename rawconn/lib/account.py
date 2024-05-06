import os, sys
from datetime import datetime
import socket, multiprocessing
import threading
from threading import Lock
import socket
from tkinter import EXCEPTION
import numpy as np
import pandas as pd
from datetime import datetime
import pytz
import io
from sqlalchemy import true

from lib.errno import *
from lib.connection import connection

global_instrument_list = {
    "XAUUSD": "XAUUSD.a",
    "EURUSD": "EURUSD.a",
    "GBPUSD": "GBPUSD.a",
}

class MT5Account:
    def __init__(self, id: int, conn: connection):
        self.id = id

        # command
        self.conn = conn
        self.connected: bool = False
        self.command: str = ''
        self.command_OK: bool = False
        self.command_return_error: str = ''
        self.debug: bool = True

        # 
        self.max_bars: int = 5000
        self.max_ticks: int = 5000
        self.timeout_value: int = 60
        self.instrument_conversion_list: dict = global_instrument_list
        self.instrument_name_broker: str = ''
        self.instrument_name_universal: str = ''
        self.date_from: datetime = '2000/01/01, 00:00:00'
        self.date_to: datetime = datetime.now()
        self.instrument: str = ''

        # static account info
        self.name: str = ''
        self.trade_mode: str = ''
        self.company: str = ''
        self.server: str = ''
        self.company: str = ''
        self.name: str = ''
        self.login: int = 0
        self.server: str = ''
        self.trade_mode: str = ''
        self.trade_allowed: str = ''
        self.leverage: int = 0
        self.currency: str = ''
        self.balance: float = 0.0
        self.credit: float = 0.0
        self.profit: float = 0.0
        self.equity: float = 0.0
        self.margin: float = 0.0
        self.margin_free: float = 0.0
        self.margin_call: float = 0.0
        self.stop_out: float = 0.0
        self.stop_out_mode: str = ''

    def __del__(self):
        print("Deleted account {} .".format(self.id))
        
    def create_empty_DataFrame(self,
                               columns, index_col) -> pd.DataFrame:
        index_type = next((t for name, t in columns if name == index_col))
        df = pd.DataFrame({name: pd.Series(dtype=t) for name,
                           t in columns if name != index_col},
                          index=pd.Index([],
                                         dtype=index_type))
        cols = [name for name, _ in columns]
        cols.remove(index_col)
        return df[cols]

    def Get_static_account_info(self):
        """
        Retrieves static account information.

        Returns: Dictionary with:
            Account name,
            Account number,
            Account currency,
            Account type,
            Account leverage,
            Account trading allowed,
            Account maximum number of pending ord   ers,
            Account margin call percentage,
            Account close open trades margin percentage
        """        
        with self.lock:
            self.command_return_error = ''
            self.command = "F001^0^"
            #self.callback = self.update_account_info_callback
            ok, dataString = self.conn.execute_cmd(self.command)
            if not ok:
                self.command_OK = False
                return None
           
            x = dataString.split('^')
            if self.debug:
                print(x)
            x.pop(-1)
            if str(x[0]) != 'F001':
                self.command_return_error = ERROR_DICT['99901']
                self.command_OK = False
                return False
           
            self.company = str(x[1])
            self.name = str(x[2])
            self.login = int(x[3])
            self.server = str(x[4])
            self.trade_mode = str(x[5])
            self.trade_allowed = str(x[6])
            self.leverage = int(x[7])
            self.currency = str(x[8])
            self.balance = float(x[9])
            self.credit = float(x[10])
            self.profit = float(x[11])
            self.equity = float(x[12])
            self.margin = float(x[13])
            self.margin_free = float(x[14])
            self.margin_level = float(x[15])
            self.margin_call = float(x[16])
            self.stop_out = float(x[17])
            self.stop_out_mode = str(x[18])
            
            if self.login != self.id:
                raise EXCEPTION("ERROR: Account ID {} and login {} mismatch!".format(self.id, self.login))

            self.command_OK = True
        return True

    def get_universal_instrument_name(self,
                                      instrumentname: str = '') -> str:
        self.instrumentname = instrumentname
        try:
            for item in self.instrument_conversion_list:
                key = str(item)
                value = self.instrument_conversion_list.get(item)
                if (value == instrumentname):
                    return str(key)
        except BaseException:
            return None
        return None

    def get_broker_instrument_name(self,
                                   instrumentname: str = '') -> str:
        self.intrumentname = instrumentname
        try:
            return self.instrument_conversion_list.get(str(instrumentname))
        except BaseException:
            return None


    def Get_instruments(self) ->list:
        """
        Retrieves broker market instruments list.

        Args:
            None
        Returns:
            List: All market symbols as universal instrument names
        """
        with self.lock:
            self.command_return_error = ''
            self.command = 'F002^0^'

            ok, dataString = self.conn.execute_cmd(self.command)
            if not ok:
                self.command_OK = False
                return None

            if self.debug:
                print(dataString)

            # analyze the answer
            return_list = []
            x = dataString.split('^')
            if x[0] != 'F002':
                self.command_return_error = ERROR_DICT['99901']
                self.command_OK = False
                return return_list
            
            #del x[0:2]
            x.pop(-1)
            for item in range(0, len(x)):
                _instrument = str(x[item])
                #instrument = _instrument
                instrument = self.get_universal_instrument_name(_instrument)
                if (instrument != None):
                    return_list.append(instrument)
            return return_list