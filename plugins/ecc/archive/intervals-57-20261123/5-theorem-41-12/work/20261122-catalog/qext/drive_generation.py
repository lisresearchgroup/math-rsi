#!/usr/bin/env python3
"""Drive the interactive GENERATION v1.1 binary (QextNewEdition, I. Bouyukliev) through a pty.

usage: drive_generation.py <rundir> <n> <k> <d> [dual_distance=2] [timeout_s=0]
Classifies all binary linear [n,k,d] codes with dual distance >= dual_distance
(menu: 2 -> n,k,d,q=2,dw=1,self-orthogonal=0 ; 5 -> dual distance ; 1 -> Start ; 8 -> Exit).
Writes <rundir>/console.log (full console transcript) and <rundir>/run.json.
One copy of the binary per directory, as its readme requires.
"""
import json
import os
import pty
import re
import select
import shutil
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    rundir = os.path.abspath(sys.argv[1])
    n, k, d = sys.argv[2], sys.argv[3], sys.argv[4]
    dual = sys.argv[5] if len(sys.argv) > 5 else '2'
    timeout = float(sys.argv[6]) if len(sys.argv) > 6 else 0.0
    os.makedirs(rundir, exist_ok=True)
    exe = os.path.join(rundir, 'generation1.1')
    shutil.copy(os.path.join(HERE, 'gen11', 'generation1.1'), exe)
    os.chmod(exe, 0o755)
    answers = ['2', n, k, d, '2', '1', '0', '5', dual, '1']
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(rundir)
        os.execv(exe, [exe])
    log = open(os.path.join(rundir, 'console.log'), 'wb')
    t0 = last = time.time()
    ai = 0
    tail = b''
    done = False
    status = None
    while True:
        r, _, _ = select.select([fd], [], [], 0.5)
        if r:
            try:
                data = os.read(fd, 65536)
            except OSError:
                data = b''
            if not data:
                break
            log.write(data)
            log.flush()
            tail = (tail + data)[-4000:]
            last = time.time()
            if not done and ai == len(answers) and b'Constructed codes' in tail:
                done = True
        else:
            idle = time.time() - last
            if ai < len(answers) and idle > 0.8:
                os.write(fd, (answers[ai] + '\n').encode())
                ai += 1
                last = time.time()
            elif done and idle > 1.5:
                os.write(fd, b'8\n')
                last = time.time()
            p, st = os.waitpid(pid, os.WNOHANG)
            if p:
                status = st
                break
        if timeout and time.time() - t0 > timeout:
            os.kill(pid, 9)
            os.waitpid(pid, 0)
            status = 'timeout'
            break
    if status is None:
        try:
            _, status = os.waitpid(pid, 0)
        except ChildProcessError:
            status = 'gone'
    log.close()
    txt = open(os.path.join(rundir, 'console.log'), 'rb').read().decode('latin1')
    m = re.findall(r'Constructed codes:\s*(\d+)', txt)
    e = re.findall(r'Elapsed time:\s*([0-9.]+)s', txt)
    out = {'n': int(n), 'k': int(k), 'd': int(d), 'dual_distance': int(dual), 'status': status,
           'constructed_codes': int(m[-1]) if m else None, 'elapsed_reported_s': float(e[-1]) if e else None,
           'wall_s': round(time.time() - t0, 1), 'completed': done}
    json.dump(out, open(os.path.join(rundir, 'run.json'), 'w'), indent=1)
    print(json.dumps(out))


if __name__ == '__main__':
    main()
