from zope.interface import Interface, Attribute, implements
from twisted.python.components import registerAdapter
from twisted.web.server import Session
from twisted.web.resource import Resource

class IUserSession(Interface):
    value = Attribute("An Userobject")

class UserSession(object):
    implements(IUserSession)
    def __init__(self, session):
        self.value = None

registerAdapter(UserSession, Session, IUserSession)
