from wsgidav.dc.base_dc import BaseDomainController


class NullDomainController(BaseDomainController):
	def __init__(self, wsgidav_app, config):
		super().__init__(wsgidav_app, config)

	def __str__(self):
		return f"{self.__class__.__name__}()"

	def get_domain_realm(self, path_info, environ):
		return self._calc_realm_from_path_provider(path_info, environ)

	def require_authentication(self, realm, environ):
		return True

	def supports_http_digest_auth(self):
		return False

	def basic_auth_user(self, realm, user_name, password, environ):
		return False
