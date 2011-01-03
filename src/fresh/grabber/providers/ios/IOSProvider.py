# Copyright (C) 2007-2010 Samuel Abels.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
import re
from providers           import Provider
from Exscript.util.match import first_match
from providers.ios.util  import remove_passwords_from_config, \
                                remove_descriptions_from_config

class IOSProvider(Provider):
    def get_hostname(self, conn):
        host = conn.get_host()
        if host.get('__cfg_hostname__'):
            return host.get('__cfg_hostname__')
        conn.execute('show configuration | i ^hostname')
        hostname = first_match(conn, r'hostname (\S+)')
        host.set('__cfg_hostname__', hostname)
        return hostname

    def remove_passwords_from_config(self, config):
        return remove_passwords_from_config(config)

    def remove_descriptions_from_config(self, config):
        return remove_descriptions_from_config(config)

    def init(self, conn):
        # Init the connection.
        conn.execute('term len 0')
        conn.execute('term width 0')
        conn.set_timeout(15 * 60)

        # Define a more reliable prompt.
        hostname = self.get_hostname(conn)
        prompt   = r'[\r\n]' + hostname + r'[#>] ?$'
        conn.set_prompt(re.compile(prompt))

        # Whenever connection.execute() is called, clean
        # the response up.
        oldexecute = conn.execute
        def execute_wrapper(command):
            oldexecute(command)
            response = conn.response.translate(None, '\r\x00')

            # Strip the command from the response.
            response = response.split('\n')
            if response:
                response.pop(0)
            while response and '#' + command in response[0]:
                response.pop(0)
            conn.response = '\n'.join(response) + '\n'

        conn.execute = execute_wrapper