# download musicbrainz
from subprocess import call
import sys, os, argparse
from ftplib import FTP

def execute_wrapper(cmd, logger=None, cwd=None):
    try:
        if cwd is not None:
            retcode = call(cmd, shell=True, cwd=cwd)
        else:
            retcode = call(cmd, shell=True)
        if retcode != 0:
            error_message = "Child was terminated by signal {0}".format(retcode)
            if logger is not None:
                logger.info(error_message)
            else:
                print >>sys.stderr, error_message
            return retcode
        else:
            message = "Child returned {0}".format(0)
            if logger is not None:
                logger.debug(message)
            else:
                print >>sys.stderr, message
            return retcode
    except OSError, e:
        if logger is not None:
            logger.exception("Execution failed")
        else:
            print >>sys.stderr, "Execution failed:", e
        return -1

def sizeof_fmt(num):
    for x in ['bytes','KB','MB','GB','TB']:
        if num < 1024.0:
            return "%3.1f %s" % (num, x)
        num /= 1024.0

MB_SERVER = "ftp.musicbrainz.org"
MB_PATH = "pub/musicbrainz/data/fullexport/"

def download_data(path):
    """ downloads data and writes to `path`
        data will be in {path}/mbdump and {path}/coverart
    """
    c = {"count" : 0}
    ftp = FTP(MB_SERVER)
    ftp.login()
    ftp.cwd(MB_PATH)
    print "** connection created"

    files = ftp.nlst()
    curr_data = None
    for f in files:
        if "latest-is" in f:
            curr_data = f.replace("latest-is-","")
            break

    print "latest is:", curr_data
    ftp.cwd(curr_data)

    mbdump_filename = "mbdump.tar.bz2"
    mbdump_path = os.path.join(path, 'mbdump')

    caa_filename = "mbdump-cover-art-archive.tar.bz2"
    caa_path = os.path.join(path, 'coverart')

    print "-- create directory if not present"
    execute_wrapper("mkdir -p {0}".format(path))


    c = {"count" : 0}
    total_size = 100
    def handleDownload(block):
        c["count"] += len(block)
        ct = int(c['count'])
        pct = int(40 * float(ct) / float(total_size))
        sys.stdout.write('\r')
        sys.stdout.write("[%-40s] %d%% (%s/%s)" % ('='*pct, 2.5*pct, sizeof_fmt(ct), sizeof_fmt(total_size)))
        sys.stdout.flush()
        f.write(block)

    for fn, fp in [(mbdump_filename, mbdump_path), (caa_filename, caa_path)]:
        print "DOWNLOAD", fn, "TO", fp
        execute_wrapper("mkdir -p {0}".format(fp))
        temp1 = os.path.join(path, fn)
        total_size = ftp.size(fn)
        with open(temp1, 'wb') as f:
            ftp.retrbinary('RETR ' + fn, handleDownload)

        print "-- unzip"
        execute_wrapper("bunzip2 {0}".format(temp1))
        temp2 = os.path.join(path, fn.replace(".bz2", ""))
        temp3 = os.path.join(path, "dl")
        execute_wrapper("mkdir -p {0}".format(temp3))

        print "-- untar"
        cmd = "tar xf {0} -C {1}".format(temp2, temp3)
        execute_wrapper(cmd)
        print "expansion complete"

        print "move files"
        cmd = "mv {0} {1}".format(os.path.join(temp3, "mbdump", "*"), fp)
        execute_wrapper(cmd)

        # cleanup
        print "-- rm", temp1
        cmd = "rm {0}".format(temp1)
        execute_wrapper(cmd)
        print "-- rm", temp2
        cmd = "rm {0}".format(temp2)
        execute_wrapper(cmd)
        print "-- rm", temp3
        cmd = "rm -rf {0}".format(temp3)
        execute_wrapper(cmd)

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='[DESCRIPTION].')
    parser.add_argument('--path', default=None, help='what directory path should we download to?')
    parser.add_argument('--verbose', action='store_true', default=True)
    # --- anything else ---

    args = parser.parse_args()
    download_data(args.path)


