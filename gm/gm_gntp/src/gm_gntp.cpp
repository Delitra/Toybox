// $Id$
/*
 * Copyright (c) 2010 sk89q <http://www.sk89q.com>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "GMLuaModule.h"
#include "growl.h"

GMOD_MODULE(Open, Close);

LUA_FUNCTION(growl_notify)
{
	ILuaInterface *gLua = Lua();
	for (int i = 1; i < 6; i++) {
		gLua->CheckType(i, GLua::TYPE_STRING);
	}
	const char *server = gLua->GetString(1);
	const char *appname = gLua->GetString(2);
	const char *notify = gLua->GetString(3);
	const char *title = gLua->GetString(4);
	const char *message = gLua->GetString(5);
	const char *password = gLua->GetString(6);
	growl_udp(server, appname, notify, title, message, "", password, "");

	return 1;
}

int Open(lua_State* L)
{
	ILuaInterface *gLua = Lua();
	ILuaObject* gntp = gLua->GetNewTable();
	gntp->SetMember("Notify", growl_notify);
	gLua->SetGlobal("gntp", gntp);
	gntp->UnReference();

	return 0;
}

int Close(lua_State* L)
{
	return 0;
}