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

class JunOSProvider(Provider):
    def get_hostname(self, conn):
        host = conn.get_host()
        if host.get('__cfg_hostname__'):
            return host.get('__cfg_hostname__')
        conn.execute('show version | match ^Hostname')
        hostname = first_match(conn, r'Hostname: (\S+)')
        host.set('__cfg_hostname__', hostname)
        return hostname

    def _cleanup_xml(self, xml):
        ns_url  = 'http://xml.juniper.net/junos/'
        ns_type = '(?:chassis|interface)'
        ns      = '("' + ns_url + ')\S+(/junos-' + ns_type + '")'
        ns_re   = re.compile(ns)
        return ns_re.sub(r'\1VERSION\2', xml)

    def remove_passwords_from_config(self, config):
        """
        Redacts the following lines in a config::

            enable secret 5 xxxxxxxxxxxxxxxxxxxxxxxxxxx
            username NIC password 7 xxxxxxxxxxxxxxxxxxxxx
             domain-password xxxxxx
             area-password xxxxx
             set community xxxxxxxxx xxxxxxxxx
             snmp-server community xxxxxx RO 10
             snmp-server community xxxxxxxxxxxxxxxxxxx view writeNet RW 12
             snmp-server host 153.17.105.9 xxxxxxxx
             password 7 xxxxxxxxxxxxxxxxx
             tacacs-server key xxxxxxxxxxxxxxxxxxxxxxxxx
             radius-server key xxxxxxxxxxxxxxxxxxxxxxxxx
        """
        patterns = (re.compile(r'(.*authentication-key) (".+")'),
                    re.compile(r'(.*encrypted-password) (".+")'))

        lines = []
        for line in config.split('\n'):
            for regex in patterns:
                line = regex.sub(r'\1 "REMOVED"', line)
            lines.append(line)
        return '\n'.join(lines)

    def init(self, conn):
        # Init the connection.
        conn.execute('set cli screen-length 0')
        conn.execute('set cli screen-width 0')
        conn.set_error_prompt(re.compile('^(unknown|invalid|error)', re.I))
        conn.set_timeout(20 * 60)

        # Define a more reliable prompt.
        hostname = self.get_hostname(conn)
        prompt   = r'[\r\n]\w+@' + hostname + r'[#>] ?$'
        conn.set_prompt(re.compile(prompt))

        # Whenever connection.execute() is called, clean
        # the response up.
        oldexecute = conn.execute
        def execute_wrapper(command):
            oldexecute(command)
            response = conn.response.translate(None, '\r\x00')

            # Strip the command from the response.
            response = response.split('\n')
            response.pop(0)
            conn.response = '\n'.join(response) + '\n'

            # HACK: Cleanup XML namespaces to make them more suitable for
            # conversion using XSLT.
            if '| display xml' in command:
                conn.response = self._cleanup_xml(conn.response)

        conn.execute = execute_wrapper
