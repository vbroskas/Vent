// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import { Socket, Presence } from "phoenix"

const chatSocket = new Socket("/chat_socket", { params: { token: window.userToken, user_id: window.user_id, username: window.username, role: window.role } })


if (window.userToken) {


	const chatChannel = chatSocket.channel(`chat:${window.roomId}`)
	let presence = new Presence(chatChannel)
	let presChange = document.querySelector("#pres-change")
	let chatInput = document.querySelector("#chat-input")
	let chatEnterBtn = document.querySelector("#enter-chat-btn")
	let messagesContainer = document.querySelector("#messages")
	const typingTimeout = 2000;
	var typingTimer;
	let userTyping = false;

	chatInput.addEventListener('keydown', () => {
		userStartsTyping()
		clearTimeout(typingTimer);
	})

	chatInput.addEventListener('keyup', () => {
		clearTimeout(typingTimer);
		typingTimer = setTimeout(userStopsTyping, typingTimeout);
	})

	chatInput.addEventListener("keypress", event => {

		if (event.key === 'Enter') {
			chatChannel.push("new_msg", { body: chatInput.value })
			chatInput.value = ""
		}
	})

	chatEnterBtn.addEventListener("click", event => {


		chatChannel.push("new_msg", { body: chatInput.value })
		chatInput.value = ""

	})


	chatChannel.on("new_msg", payload => {
		var today = new Date()
		var time = today.getHours() + ":" + today.getMinutes()
		let messageItem = document.createElement("p")
		messageItem.classList.add("message")
		messageItem.innerText = `[${payload.username}: ${time}] ${payload.body}`
		messagesContainer.appendChild(messageItem)

		const targetNode = document.querySelector("#messages")
		targetNode.scrollTop = targetNode.scrollHeight
	})


	// chatChannel.on("presence_state", state => {
	// 	presences = Presence.syncState(presences, state)
	// 	renderOnlineUsers(presences)
	// })

	// chatChannel.on("presence_diff", diff => {
	// 	presences = Presence.syncDiff(presences, diff)
	// 	renderOnlineUsers(presences)
	// })

	const userStartsTyping = function () {
		if (userTyping) { return }

		userTyping = true
		chatChannel.push('user:typing', { typing: true })
	}

	const userStopsTyping = function () {
		clearTimeout(typingTimer);
		userTyping = false
		chatChannel.push('user:typing', { typing: false })
	}

	const onlineUserTemplate = function (user) {
		var typingIndicator = ''
		if (user.typing) {
			typingIndicator = 'typing'
		}

		return `<div id="online-user-${user.user_id}">
		<strong class="${typingIndicator}">${user.username}</strong> 
	  </div>`
	}



	function renderOnlineUsers(presence) {
		console.log("IN RENDER USERS")

		let onlineUsers = presence.list((id, { metas: [user, ...rest] }) => {
			return onlineUserTemplate(user)
		}).join("")

		document.querySelector("#online-users").innerHTML = onlineUsers
	}

	chatSocket.connect()
	chatSocket.onOpen(() => console.log('chatSocket connected'))
	presence.onSync(() => renderOnlineUsers(presence))


	chatChannel.join()
		.receive("ok", resp => { console.log("Joined Chat:", resp.room_id, "name:", resp.username) })
		.receive("error", resp => { console.log("Unable to join  chat", resp.user_id) })
		.receive("timeout", (resp) => console.error("chat timeout", resp.user_id))


}






export { chatSocket as chatSocket };

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `: current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:





// export default chatSocket
