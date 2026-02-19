from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.plugins.callback import CallbackBase
from ansible.errors import AnsibleError

DOCUMENTATION = '''
    callback: strict_deprecations
    type: notification
    short_description: Fail on any deprecation warning
    description:
      - This callback plugin raises a fatal error whenever a deprecation warning is issued.
      - Use to enforce zero-tolerance for deprecations.
    requirements:
      - enable in ansible.cfg (callback_whitelist)
'''

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'strict_deprecations'

    def v2_playbook_on_start(self, playbook):
        print("STRICT DEPRECATION PLUGIN LOADED AND ACTIVE")

    def v2_runner_on_ok(self, result):
        pass

    def v2_runner_on_warning(self, result, msg=""):
        print(f"DEBUG: Warning callback detected: {msg}")
        if "DEPRECATION" in str(msg).upper():
             raise AnsibleError(f"DEPRECATION WARNING (via warning callback): {msg}")

    def v2_runner_on_deprecation(self, result, path=None, lines=None, msg=None, removed_in=None):
        print(f"DEBUG: Deprecation callback detected! msg={msg}")
        error_msg = f"DEPRECATION WARNING (Strict Mode): {msg}"
        if path:
            error_msg += f" (in {path})"
        raise AnsibleError(error_msg)
