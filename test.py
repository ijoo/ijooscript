#!/usr/bin/env python3
import os
import time
import traceback
import requests
import json

def wMerah(wrn): print("\033[91m {}\033[00m" .format(wrn))
def wCyan(wrn): print("\033[96m {}\033[00m" .format(wrn))
def PutihBGBiru(wrn): print("\x1b[1;97;44m {}\x1b[0m" .format(wrn))
def HitamBGKuning(wrn): print("\x1b[1;30;43m {}\x1b[0m" .format(wrn))
def MerahBGPutih(wrn): print("\x1b[1;31;107m {}\x1b[0m" .format(wrn))
def garisbawah(wrn): print("\x1b[4m {}\x1b[0m" .format(wrn))
def ijoobanner():
	wMerah("""
	
     ██╗██╗  ██╗███████╗██╗  ██╗████████╗
     ██║██║  ██║██╔════╝╚██╗██╔╝╚══██╔══╝
     ██║███████║█████╗   ╚███╔╝    ██║   
     ██║██╔══██║██╔══╝   ██╔██╗    ██║   
     ██║██║  ██║███████╗██╔╝ ██╗   ██║   
     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   
        IJOO HARDSUB & SUBS EXTRACTOR       
	""")

ijoobanner()
def xbanner(): PutihBGBiru("                      Extrak Menu      ")
def hydraxbanner(): PutihBGBiru("             H.Y.D.R.A.X               ")
def qbanner(): MerahBGPutih("     See You Soon...! Bye...           ")
def hbanner(): HitamBGKuning("                     HardSub Menu      ")
def extract_m():
    while(True):
        xbanner()
        print_extract()
        option = ''
        try:
            option = int(input("Masukan Pilihan: "))
        except:
            print("Input Salah, Masukan hanya angka ...")
        if option == 1:
            extract_s()
            break
        elif option == 2:
            extract_f()
            break
        elif option == 3:
            qbanner()
            exit()
        else:
            print("Invalid option. Please enter a number between 1 and 3.")

def extract_s():
        satufile = input("Masukan Nama File: ")
        print("Nama File yang akan diextract \x1b[4m" + satufile + "\x1b[0m")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           os.system("ffmpeg -i {0} -f webvtt {0}.vtt".format(satufile))
           os.system("ffmpeg -i {0}.vtt {0}.srt".format(satufile))
           print("Extracted!")
        else:
           qbanner()

def extract_f():
        folderext = input("Masukan ext Video (ex: .mp4): ")
        folderstream = input("Masukan No Stream: ")
        print("Ext yang akan di extract \x1b[4m" + folderext + "\x1b[0m, dengan No Stream \x1b[4m" + folderstream + "\x1b[0m")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           mycwd = os.getcwd()
           for namafile in os.listdir(mycwd):
              if namafile.endswith(folderext):
                 os.system("ffmpeg -i {0} -map 0:s:{1} {0}.srt".format(namafile,folderstream))
                 print("Saved to {0}.srt ".format(namafile))
        else:
           qbanner()

def hardsub_s():
        satufile = input("Masukan Nama File (ex: venom.mp4): ")
        satusrt = input("Masukan Nama Subs (ex: venom.srt): ")
        print("Video \x1b[4m" + satufile + "\x1b[0m Akan di HARDSUB dengan \x1b[4m" + satusrt + "\x1b[0m")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           print("Hardsub single! Video {0} dengan Subs {1}" .format(satufile, satusrt))
           os.system("ffmpeg -i {0} -vf subtitles={1} -vcodec copy -acodec copy {0}.mp4". format(satufile,satusrt))
        else:
           qbanner()

def hardsub_f():
        folderext = input("Masukan Ext Video with . (ex: .mp4): ")
        foldersrt = input("Masukan Ext Subs with . (ex: .srt): ")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           mycwd = os.getcwd()
           for namafile in os.listdir(mycwd):
              if namafile.endswith(folderext):
                 print("HARD SUB " + namafile + " >> " + namafile + foldersrt)
                 os.system("ffmpeg -i {0} -vf subtitles={0}{1} -vcodec copy -acodec copy {0}.mp4". format(namafile,foldersrt))
        else:
           qbanner()

def hardsub_m():
    while(True):
        hbanner()
        print_hardsub()
        option = ''
        try:
            option = int(input("Masukan Pilihan: "))
        except:
            print("Input Salah, Masukan hanya angka ...")
        if option == 1:
            hardsub_s()
            break
        elif option == 2:
            hardsub_f()
            break
        elif option == 3:
            qbanner()
            exit()
        else:
            print("Invalid option. Please enter a number between 1 and 3.")


def upload_m():
    while(True):
        print_upload()
        option = ''
        try:
            option = int(input("Masukan Pilihan: "))
        except:
            print("Input Salah, Masukan hanya angka ...")
        if option == 1:
            hydrax_m()
            break
        elif option == 2:
            hydrax_m()
            break
        elif option == 3:
            hydrax_m()
            break
        elif option == 4:
            hydrax_m()
            break
        elif option == 5:
            hydrax_m()
            break
        elif option == 6:
            qbanner()
            exit()
        else:
            print("Invalid option. Please enter a number between 1 and 6.")

def hydrax_m():
    while(True):
        hydraxbanner()
        print_hydrax()
        option = ''
        try:
            option = int(input("Masukan Pilihan: "))
        except:
            print("Input Salah, Masukan hanya angka ...")
        if option == 1:
            hydrax_s()
            break
        elif option == 2:
            hydrax_f()
            break
        elif option == 3:
            qbanner()
            exit()
        else:
            print("Invalid option. Please enter a number between 1 and 3.")

def hydrax_s():
        satufile = input("Masukan Nama File: ")
        print("Uploading Video \x1b[4m" + satufile + "\x1b[0m")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           split_tup = os.path.splitext(satufile)
           dapatext = split_tup[1]
           dapatdot = dapatext.split(".")[-1]
           print("\n")
           hydrax_u(dapatdot,satufile)
        else:
           qbanner()
        print("\n      \x1b[1;97;104m H.Y.D.R.A.X \x1b[0m \x1b[1;32;104m Selesai! \x1b[0m\n\n")

def hydrax_f():
        folderext = input("Masukan Ext Video (ex: mp4): ")
        user_input = input('Apakah yang ingin melanjutkan (y/n): ')
        if user_input.lower() == 'y':
           mycwd = os.getcwd()
           for namafile in os.listdir(mycwd):
              if namafile.endswith(folderext):
                 print("\n")
                 hydrax_u(folderext,namafile)
        else:
           qbanner()
        print("\n      \x1b[1;97;104m H.Y.D.R.A.X \x1b[0m \x1b[1;32;104m Selesai! \x1b[0m\n\n")

def hydrax_u(ty, tt):
        print("      \x1b[1;97;104m H.Y.D.R.A.X \x1b[0m \x1b[1;97;43m Uploading.. \x1b[0m \x1b[4;97m" + tt + "\x1b[0m")
        url = url = "http://up.hydrax.net/a31e01ae9b6afc4d0ce238113ca580e6"
        hfile_type = "video/" + ty
        hfile_path = "./" + tt
        hfiles = { 'file': (tt, open(hfile_path, 'rb'), hfile_type) }
        hr = requests.post(url, files=hfiles)
        hy = json.loads(hr.text)
        hx = hy["slug"]
        print("          \x1b[1;97mDone!! >> https://pemutar.xyz/v=" + hx + "\x1b[0m")

menu_options = {
    1: 'Extract Subtitles',
    2: 'Make HardSub',
    3: 'Upload to Video Hosting',
    4: 'Exit',
}

extract_options = {
    1: 'Single Files',
    2: 'Extract files in Folder',
    3: 'Exit',
}

hardsub_options = {
    1: 'Single Video',
    2: 'All Video in Folder',
    3: 'Exit',
}

upload_options = {
    1: 'Hydrax',
    2: 'DoodStream',
    3: 'Upstream',
    4: 'StreamSB',
    5: 'All Hosting',
    6: 'Exit',
}

hydrax_options = {
    1: 'HX Single Files',
    2: 'HX All Files',
    3: 'HX Exit',
}

def print_menu():
    for key in menu_options.keys():
        print (key, '--', menu_options[key] )

def print_extract():
    for key in extract_options.keys():
        print (key, '--', extract_options[key] )

def print_hardsub():
    for key in hardsub_options.keys():
        print (key, '--', hardsub_options[key] )

def print_upload():
    for key in upload_options.keys():
        print (key, '--', upload_options[key] )

def print_hydrax():
    for key in hydrax_options.keys():
        print (key, '--', hydrax_options[key] )


if __name__=='__main__':
    while(True):
        print_menu()
        option = ''
        try:
           option = int(input("Masukan Pilihan: "))
        except:
           print("Input Salah, Masukan hanya angka ...")
        #Check what choice was entered and act accordingly
        if option == 1:
           extract_m()
           break
        elif option == 2:
           hardsub_m()
           break
        elif option == 3:
           upload_m()
           break
        elif option == 4:
           qbanner()
           exit()
        else:
           print("Invalid option. Please enter a number between 1 and 4.")

