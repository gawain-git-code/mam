##################################
from enum import Enum, auto
import select

class JobType(Enum):
    DEFAULT = auto()
    SENDRECEV = auto()
    RECVONLY = auto()

class JobStatus(Enum):
    DEFAULT = auto()
    START = auto()
    READ = auto()
    WRITE = auto()
    ERROR = auto()

class NewJob:
    def __init__(self):
        self.job_type = JobType.DEFAULT
        self.id = None
        self.sock = None
        self.cmd: str = ''
        self.write_size: int = 1024
        self.read_size: int = 1024
        self.dataq = multiprocessing.Queue()
        self.status = JobStatus.DEFAULT
        self.error_msg: str = ''
        self.error_no: int = ''

# job_queue, job_receipt = multiprocessing.Queue()
def exchange_center(job_queue, job_receipt):
    job_queue = multiprocessing.Queue()
    job_receipt = multiprocessing.Queue()
    job = NewJob()
    # init
    job_list = {}
    sock_list = []

    # loop begins here
    inputs = []
    outputs = []
    # get the job and add it to list
    while not job_queue.empty():
        job = job_queue.get()
        job_list[job.sock] = job
        sock_list.append(job.sock)

        if job.job_type == JobType.SENDRECEV:
            inputs.append(job.sock)
            job.status = JobStatus.WRITE

        elif job.job_type == JobType.RECVONLY:
            inputs.append(job.sock)
            job.status = JobStatus.READ

    # Set all sockets to non-blocking
    readable, writable, exceptional = select.select(inputs, outputs, sock_list)

    # Process read operation
    for sock in readable:
        working_job = job_list[sock]
        
        data_received = sock.recv(500000).decode()
        if data_received:
            # A readable client socket has data
            # put data
            working_job.dataq.put(data_received)
            # update job status
            if working_job.job_type == JobType.SENDRECEV:
                # prepare for write stage
                working_job.status = JobStatus.WRITE
                if sock not in outputs:
                    outputs.append(sock)

        else:
            # Interpret empty result as closed connection
            # stop listening for input on the connection
            # clean up sock and job
            print >>sys.stderr, 'closing ', working_job.id, ' after reading no data'
            # update job status
            working_job.status = JobStatus.ERROR
            working_job.error_msg = "Read from sock raised exception."
            if sock in outputs:
                outputs.remove(sock)
            inputs.remove(sock)
            sock_list.remove(sock)
            sock.close()

    for sock in writable:
        working_job = job_list[sock]
        
        if working_job.status != JobStatus.WRITE:
            print >>sys.stderr, 'Wrong Job status to send to %s' % (working_job.id)
        
        print >>sys.stderr, 'sending cmd to %s' % (working_job.id)
        try:
            sock.send(bytes(str(working_job.cmd), "utf-8"))
        except:
            # broken socket connection
            working_job.status = JobStatus.ERROR
            working_job.error_msg = "Send to sock raised exception."
            outputs.remove(sock)
            sock_list.remove(sock)
            sock.close()


##################################