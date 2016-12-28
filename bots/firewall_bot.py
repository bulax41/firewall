#!/usr/bin/env python

import subprocess
import select
import sys
import datetime
import time
import re
import json
import socket
import os
import configparser
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters
import logging

config = configparser.ConfigParser()
config.read('bot.ini')
savefile = config['FILES']['chats']
user_token = config['TOKENS']['user']
admin_token = config['TOKENS']['admin']

# Enable logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.INFO)
logger = logging.getLogger(__name__)

def _messageUsers(message):
    return

def _messageAdmins(message):
    return

def tokens(bot,update):
    if _auth(update,admin=True) == False:
        return

    update.message.reply_text(
        """
        User registration token: %s
        Admin registration token: %s
        """ % (user_token,admin_token)
        )
    return


def who(bot,update):
    global userList
    if _auth(update) == False:
        return

    for user in userList.keys():
        admin = ""
        if userList[user]["admin"]:
            admin = ", Admin"
        msg = "%s %s, %s %s" % (userList[user]["first_name"],userList[user]["last_name"],userList[user]["username"],admin)
        update.message.reply_text(msg)
    return

def _auth(update,admin=False):
    global userList
    user = update.message.from_user

    if update.message.chat.type != "private":
        update.message.reply_text("Sorry %s, I prefer only private chats." % user.first_name)
        return(False)

    if userList.has_key(str(user.id)):
        if admin:
            return(userList[str(user.id)]["admin"])
        return(True)

    update.message.reply_text("I'm sorry %s.  I am not sure chatting with you is a good idea right now." % user.first_name)
    return(False)

def _add_user(update,admin=False):
    global userList
    userList[str(update.message.from_user.id)] = {
        "admin":admin,
        "chat_id":update.message.chat.id,
        "first_name": update.message.from_user.first_name,
        "last_name": update.message.from_user.last_name,
        "username": update.message.from_user.username
    }

    with open(savefile, 'w') as f:
        json.dump(userList,f)

    return

def register(bot, update, args):
    global userList
    user = update.message.from_user

    token = " ".join(args)
    if token == user_token:
        if userList.has_key(str(user.id)):
            update.message.reply_text("%s, you have already registered." % user.first_name)
            return
        _add_user(update)
    elif token == admin_token:
        if userList.has_key(str(user.id)):
            if userList[str(user.id)]["admin"]:
                update.message.reply_text("%s, you are already and admin." % user.first_name)
                return
        else:
            _add_user(update,admin=True)
            update.message.reply_text("%s, you are now an admin. Wield the power with care.  Check out the /help menu to see the new commands." % user.first_name)
            return
    else:
        update.message.reply_text("Hi %s, I can't register you. " % user.first_name )
        return

    update.message.reply_text("Welcome %s! If you need help just ask. /help" % user.first_name)

    _messageAdmins(user.first_name)

    return


def blackhole(bot, update, args):
    global bh_ips
    msg = ""
    if _auth(update) == False:
        return

    if _auth(update,admin=True) == True:
        msg = "I have blackhole %s" % " ".join(args)
    else:
        msg = "Hmmm...  Let me check to see if I can do that for you."

    update.message.reply_text(msg)

def bhlist(bot, update):
    global bh_ips
    if _auth(update) == False:
        return

    ips = "\n".join(bh_ips)
    text = "List of Blackholed IP's:\n %s " % ips
    update.message.reply_text(text)


def help(bot, update):
    global userList
    if _auth(update) == False:
        return

    user = update.message.from_user
    if _auth(update,admin=True):
        m = """
        *Admin Commands*
        /blackhole {IP}    : This will blackhole the IP on the network and with our upstream peeers
        /tokens   :  Replies with the registration tokens
        """
        update.message.reply_text(m)

    update.message.reply_text(
        """
        *User menu*
        /bhlist  :  List the IP's currently blackholed on the network.
        /who   : List the registered users.
        /register {token}  : This is to register with the Bot or upgrade an account to an admin.
        """
        )

def echo(bot, update):
    if _auth(update) == False:
        return

    update.message.reply_text(update.message.text)

def add_ip(bot,update,args):
    try:
        socket.inet_aton(args[0])
    except:
        update.message.reply_text("Invalid IP '%s'." % " ".join(args))
        return

    # call thess
    os.chdir("/root/firewall")

    try:
        output = subprocess.check_output(["/root/firewall/mkfw-ip",args[0]],stderr=subprocess.STDOUT)
        status="Sucess"
    except subprocess.CalledProcessError as oops:
        status="Error"
        output = oops.output

    update.message.reply_text("%s: %s" % (status,output))
    return

def error(bot, update, error):
    logger.warn('Update "%s" caused error "%s"' % (update, error))

def unknownCmd(bot, update):
    if _auth(update) == False:
        return
    update.message.reply_text("Hi %s, not sure I understand, please ask for /help if needed." % update.message.from_user.first_name)
    return

def main():
    global userList
    userList = {}

    # open up previous authenticated chat users
    try:
        with open(savefile, 'r') as f:
            try:
                userList = json.load(f)
            except ValueError:
                print "No users to load"
                pass
    except:
        pass

    # Create the EventHandler and pass it your bot's token.
    updater = Updater(config['TOKENS']['bot_api'])

    # Get the dispatcher to register handlers
    dp = updater.dispatcher

    # on different commands - answer in Telegram
    dp.add_handler(CommandHandler("register", register,pass_args=True))
    dp.add_handler(CommandHandler("help", help))
    dp.add_handler(CommandHandler("bhlist", bhlist))
    dp.add_handler(CommandHandler("blackhole", blackhole,pass_args=True))
    dp.add_handler(CommandHandler("who", who))
    dp.add_handler(CommandHandler("tokens", tokens))
    dp.add_handler(CommandHandler("addip", add_ip,pass_args=True))

    dp.add_handler(MessageHandler(Filters.command,help))
    dp.add_handler(MessageHandler(Filters.text, help))

    # log all errors
    dp.add_error_handler(error)

    # Start the Bot
    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
