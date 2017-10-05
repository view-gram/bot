redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
    	print("\n\27[36m                      id asli 250507046 --- 395298936 << \n >> plz imput ID number :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("botBOT-IDadmin")
    	redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botBOT-IDid",naji.id_)
		if naji.first_name_ then
			redis:set("botBOT-IDfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botBOT-IDlanme",naji.last_name_)
		end
		redis:set("botBOT-IDnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "<i>OK.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 1 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 200
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		if redis:get('botBOT-IDmaxgpmmbr') then
			if naji.member_count_ >= tonumber(redis:get('botBOT-IDmaxgpmmbr')) then
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDgoodlinks", i.link)
			else
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDsavedlinks", i.link)
			end
		else
			redis:srem("botBOT-IDwaitelinks", i.link)
			redis:sadd("botBOT-IDgoodlinks", i.link)
		end
	elseif naji.code_ == 1 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 200
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if redis:get("botBOT-IDstart") then
			redis:del("botBOT-IDstart")
			tdcli_function ({
				ID = "GetChats",
				offset_order_ = 9223372036854775807,
				offset_chat_id_ = 0,
				limit_ = 10000},
			function (i,naji)
				local list = redis:smembers("botBOT-IDusers")
				for i, v in ipairs(list) do
					tdcli_function ({
						ID = "OpenChat",
						chat_id_ = v
					}, dl_cb, cmd)
				end
			end, nil)
		end
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in ipairs(links) do
					if x == 2 then redis:setex("botBOT-IDmaxlink", 70, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if redis:get("botBOT-IDmaxgroups") and redis:scard("botBOT-IDsupergroups") >= tonumber(redis:get("botBOT-IDmaxgroups")) then 
			redis:set("botBOT-IDmaxjoin", true)
			redis:set("botBOT-IDoffjoin", true)
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 1 then redis:setex("botBOT-IDmaxjoin", 270, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 987654321) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(del link) (.*)$") then
					local matches = text:match("^del link (.*)$")
					if matches == "join" then
						redis:del("botBOT-IDgoodlinks")
						return send(msg.chat_id_, msg.id_, "remove links whait join!")
					elseif matches == "config" then
						redis:del("botBOT-IDwaitelinks")
						return send(msg.chat_id_, msg.id_, "remove links config for join!")
					elseif matches == "save" then
						redis:del("botBOT-IDsavedlinks")
						return send(msg.chat_id_, msg.id_, "remove links save in data!")
					end
				elseif text:match("^(del links) (.*)$") then
					local matches = text:match("^del links (.*)$")
					if matches == "join" then
						local list = redis:smembers("botBOT-IDgoodlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "remove links whait join!!.")
						redis:del("botBOT-IDgoodlinks")
					elseif matches == "config" then
						local list = redis:smembers("botBOT-IDwaitelinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "remove links config for join!!.")
						redis:del("botBOT-IDwaitelinks")
					elseif matches == "save" then
						local list = redis:smembers("botBOT-IDsavedlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "remove links save in data!!")
						redis:del("botBOT-IDsavedlinks")
					end
				elseif text:match("^(stop) (.*)$") then
					local matches = text:match("^stop (.*)$")
					if matches == "join" then	
						redis:set("botBOT-IDmaxjoin", true)
						redis:set("botBOT-IDoffjoin", true)
						return send(msg.chat_id_, msg.id_, "stop join!")
					elseif matches == "config" then	
						redis:set("botBOT-IDmaxlink", true)
						redis:set("botBOT-IDofflink", true)
						return send(msg.chat_id_, msg.id_, "stop config!")
					elseif matches == "scan" then	
						redis:del("botBOT-IDlink")
						return send(msg.chat_id_, msg.id_, "stop scan!")
					elseif matches == "add number" then	
						redis:del("botBOT-IDsavecontacts")
						return send(msg.chat_id_, msg.id_, "add share number auto stoping!")
					end
				elseif text:match("^(start) (.*)$") then
					local matches = text:match("^start (.*)$")
					if matches == "join" then	
						redis:del("botBOT-IDmaxjoin")
						redis:del("botBOT-IDoffjoin")
						return send(msg.chat_id_, msg.id_, "start join")
					elseif matches == "config" then	
						redis:del("botBOT-IDmaxlink")
						redis:del("botBOT-IDofflink")
						return send(msg.chat_id_, msg.id_, "start config")
					elseif matches == "scan" then	
						redis:set("botBOT-IDlink", true)
						return send(msg.chat_id_, msg.id_, "start scan.")
					elseif matches == "add number" then	
						redis:set("botBOT-IDsavecontacts", true)
						return send(msg.chat_id_, msg.id_, "add share number auto starting.")
					end
				elseif text:match("^(max) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgroups', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i> max number groups : </i><b> "..matches.." </b>")
				elseif text:match("^(min) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgpmmbr', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>min number groups : </i><b> "..matches.." </b>")
				elseif text:match("^(del max)$") then
					redis:del('botBOT-IDmaxgroups')
					return send(msg.chat_id_, msg.id_, "remove max number")
				elseif text:match("^(del min)$") then
					redis:del('botBOT-IDmaxgpmmbr')
					return send(msg.chat_id_, msg.id_, "remove min number")
				elseif text:match("^(add admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>adding!</i>")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "your not sudo!")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>adding admin</i>")
					end
				elseif text:match("^(add sudo) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "your not sudo!")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "adding sudo")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'OK')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "adding sudo")
					end
				elseif text:match("^(del admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botBOT-IDadmin', msg.sender_user_id_)
								redis:srem('botBOT-IDmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "your not admin ")
						end
						return send(msg.chat_id_, msg.id_, "your not admin")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "error 342")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "remove admin")
					end
					return send(msg.chat_id_, msg.id_, "remove admin")
				elseif text:match("^(reset)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>reset profile bot</i>")
				elseif text:match("report") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 987654321,
						chat_id_ = 987654321,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^(list) (.*)$") then
					local matches = text:match("^list (.*)$")
					local naji
					if matches == "number" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "botBOT-ID_contacts.txt"},
								caption_ = "m.r contacts number BOT-ID"}
							}, dl_cb, nil)
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "answer auto " then
						local text = "<i>list answer :</i>\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "block" then
						naji = "botBOT-IDblockedusers"
					elseif matches == "pv" then
						naji = "botBOT-IDusers"
					elseif matches == "gp" then
						naji = "botBOT-IDgroups"
					elseif matches == "supergp" then
						naji = "botBOT-IDsupergroups"
					elseif matches == "links" then
						naji = "botBOT-IDsavedlinks"
					elseif matches == "admin" then
						naji = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "list m.r "..tostring(matches).."  BOT-ID"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(seen) (.*)$") then
					local matches = text:match("^view (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id_, msg.id_, "<code>✔✔</code>")
					elseif matches == "off" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id_, msg.id_, "<code>✔</code>")
					end 
				elseif text:match("^(add pm) (.*)$") then
					local matches = text:match("^add pm (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>pm add number on</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>pm add number off</i>")
					end
				elseif text:match("^(send number) (.*)$") then
					local matches = text:match("add numbers (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>share number online </i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id_, msg.id_, "<i>share number offline </i>")
					end
				elseif text:match("^(pm set) (.*)") then
					local matches = text:match("^pm set (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>seting </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(set anwser) "(.*)" (.*)') then
					local txt, answer = text:match('^set anwser "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i> | </i>" .. tostring(txt) .. "<i> | set :</i>\n" .. tostring(answer))
				elseif text:match("^(del answer) (.*)") then
					local matches = text:match("^del set (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i> | </i>" .. tostring(matches) .. "<i> |del set</i>")
				elseif text:match("^(auto anwser) (.*)$") then
					local matches = text:match("^auto anwser (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id_, 0, "<i>auto answer online</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id_, 0, "<i>auto answer offline.</i>")
					end
				elseif text:match("^(reload)$")then
					local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>reload! </i>")
				elseif text:match("^(#panel)$") or text:match("^(#Panel)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "<b>ONline</b>" or "<i>OFFline</i>"
					local numadd = redis:get("botBOT-IDaddcontact") and "<b>ONline</b>" or "<i>OFFline</i>"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "<code>@bid3l</code>"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "<b>ONline</b>" or "<i>OFFline</i>"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "<i>OFFline</i>" or "<b>ONline</b>"
					local offlink = redis:get("botBOT-IDofflink") and "<i>OFFline</i>" or "<b>ONline</b>"
					local gp = redis:get("botBOT-IDmaxgroups") or "NOT set"
					local mmbrs = redis:get("botBOT-IDmaxgpmmbr") or "NOT set"
					local nlink = redis:get("botBOT-IDlink") and "<b>ONline</b>" or "<i>OFFline</i>"
					local contacts = redis:get("botBOT-IDsavecontacts") and "<b>ONline</b>" or "<i>OFFline</i>"
					local fwd =  redis:get("botBOT-IDfwdtime") and "<b>ONline</b>" or "<i>OFFline</i>" 
					local txt = "♻️<code> #panel </code>♻️\n🤖<b> Number BOT => </b><code> BOT-ID</code>\n\n"..tostring(offjoin).."<code> Auto join </code>\n"..tostring(offlink).."<code> Config link </code>\n"..tostring(nlink).."<code> Scan link </code>\n"..tostring(fwd).."<code> Anti Delete</code>\n"..tostring(contacts).."<code> Add auto number </code>\n" .. tostring(numadd) .. "<code> Add number  </code>\n➖➖➖➖➖➖\n<b> Power by :</b>\n" .. tostring(txtadd) .. "\n➖➖➖➖➖➖\n\n📥<b> Links stored </b>: \n<i>                     " .. tostring(links) .. "</i>\n⏳<b> Links waiting for join </b>: \n<i>                     " .. tostring(glinks) .. "</i>\n🔄<b> Join links new time now </b>: \n<i>                     " .. tostring(s) .. " </i> (<b>sec</b>)\n🔗<b> Check  links </b>: \n<i>                     " .. tostring(wlinks) .. "</i>\n⏳<b> Check links new time now </b>: \n<i>                     " .. tostring(ss) .. " </i>(<b>sec</b>)"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(#stats)$") or text:match("^(#Stats)$") then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[
<code>♻️ #stats ♻️</code>
<b>power by : </b><code>@Bid3l</code>
          
<b>👤 user pv : </b><i>]] .. tostring(usrs) .. [[</i>
➖➖➖➖➖➖
<b>👥 Groups : </b><i>]] .. tostring(gps) .. [[</i>
➖➖➖➖➖➖➖
<b>🌐 super Groups : </b><i>]] .. tostring(sgps) .. [[</i>
➖➖➖➖➖➖➖➖
<b>📱 Contacts : </b><i>]] .. tostring(contacts)..[[</i>
➖➖➖➖➖➖➖➖➖
<b>📂 links save : </b><i>]] .. tostring(links)..[[</i>
]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(خصوصی)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(گروه)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					if redis:get("botBOT-IDfwdtime") then
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
							if i % 4 == 0 then
								os.execute("sleep 90")
							end
						end
					else
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
						end
					end
						return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(Antidel) (.*)$") then
					local matches = text:match("^antidel (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDfwdtime", true)
						return send(msg.chat_id_,msg.id_,"<i>ONline Anti delete </i>")
					elseif matches == "off" then
						redis:del("botBOT-IDfwdtime")
						return send(msg.chat_id_,msg.id_,"<i>OFFline Anti delete </i>")
					end
				elseif text:match("^(send) (.*)") then
					local matches = text:match("^send (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    return send(msg.chat_id_, msg.id_, "<b>seccessfully</b>")
				elseif text:match("^(block) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<b>blocked!</b>")
				elseif text:match("^(unblock) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<b>unblocked</b>")	
				elseif text:match('^(set name) "(.*)" (.*)') then
					local fname, lname = text:match('^set name "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت ثبت شد.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف شد.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$") 	
					send(msg.chat_id_, msg.id_, 'تبلیغ‌گر از گروه مورد نظر خارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(افزودن به همه) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  1
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمام گروه های من دعوت شد</i>")
				elseif (text:match("^(انلاین)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(راهنما)$") then
					local txt = '📍راهنمای دستورات تبلیغ‌گر📍\n\nانلاین\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n\nافزودن مدیر شناسه\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\nافزودن مدیرکل شناسه\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\nحذف مدیر شناسه\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\nترک گروه\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\nافزودن همه مخاطبین\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\nشناسه من\n<i>دریافت شناسه خود 🆔</i>\n\nبگو متن\n<i>دریافت متن 🗣</i>\n\nارسال کن "شناسه" متن\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\nتنظیم نام "نام" فامیل\n<i>تنظیم نام ربات ✏️</i>\n\nتازه سازی ربات\n<i>تازه‌سازی اطلاعات فردی ربات🎈</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر📍)</code>\n\nتنظیم نام کاربری اسم\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\nحذف نام کاربری\n<i>حذف کردن نام کاربری ❎</i>\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\nشروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\nحداکثر گروه عدد\n<i>تنظیم حداکثر سوپرگروه‌هایی که تبلیغ‌گر عضو می‌شود،با عدد دلخواه</i> ⬆️\n\nحداقل اعضا عدد\n<i>تنظیم شرط حدقلی اعضای گروه برای عضویت,با عدد دلخواه</i> ⬇️\n\nحذف حداکثر گروه\n<i>نادیده گرفتن حدمجاز تعداد گروه</i> ➰\n\nحذف حداقل اعضا\n<i>نادیده گرفتن شرط حداقل اعضای گروه</i> ⚜️\n\nارسال زمانی روشن|خاموش\n<i>زمان بندی در فروارد و استفاده در دستور ارسال</i> ⏲\n<code>🕐 بعد از فعال‌سازی ,ارسال به 400 مورد حدودا 4 دقیقه زمان می‌برد و  تبلیغ‌گر طی این زمان پاسخگو نخواهد بود 🕐</code>\n\nافزودن با شماره روشن|خاموش\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\nافزودن با پیام روشن|خاموش\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\nتنظیم پیام افزودن مخاطب متن\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\nلیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄</i>\n\nمسدودیت شناسه\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫</i>\n\nرفع مسدودیت شناسه\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\nوضعیت مشاهده روشن|خاموش 👁\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\nامار\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\nوضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\nتازه سازی\n<i>تازه‌سازی آمار تبلیغ‌گر🚀</i>\n<code>🎃مورد استفاده حداکثر یک بار در روز🎃</code>\n\nارسال به همه|خصوصی|گروه|سوپرگروه\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😄توصیه ما عدم استفاده از همه و خصوصی😄)</code>\n\nارسال به سوپرگروه متن\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)</code>\n\nتنظیم جواب "متن" جواب\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝</i>\n\nحذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\nپاسخگوی خودکار روشن|خاموش\n<i>تغییر وضعیت پاسخگویی خودکار تبلیغ‌گر به متن های تنظیم شده 📯</i>\n\nحذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>❌\n\nحذف کلی لینک عضویت|تایید|ذخیره شده\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n🔺<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>🔻\n\nافزودن به همه شناسه\n<i>افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ➕➕</i>\n\nترک کردن شناسه\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🏃</i>\n\nراهنما\n<i>دریافت همین پیام 🆘</i>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(افزودن همه مخاطبین)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال افزودن مخاطبین به گروه ...</i>")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	end
end
