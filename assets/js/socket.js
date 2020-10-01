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


	let chatInput = document.querySelector("#chat-input")
	let messagesContainer = document.querySelector("#messages")




	chatInput.addEventListener("keypress", event => {
		if (event.key === 'Enter') {
			chatChannel.push("new_msg", { body: chatInput.value })
			chatInput.value = ""
		}
	})


	chatChannel.on("new_msg", payload => {
		let messageItem = document.createElement("p")
		messageItem.innerText = `[${payload.username}] ${payload.body}`
		messagesContainer.appendChild(messageItem)
	})

	// Presence-------------------------------

	presence.onJoin((id, current, newPres) => {
		if (!current) {
			console.log("user has entered for the first time", newPres)
		} else {
			console.log("user additional presence", newPres)
		}
	})

	presence.onLeave((id, current, leftPres) => {
		if (current.metas.length === 0) {
			console.log("user has left from all devices", leftPres)
		} else {
			console.log("user left from a device", leftPres)
		}
	})

	function renderOnlineUsers(presence) {
		let response = ""
		let thing = presence.list()
		console.log(thing)

		presence.list((id, { metas: [first, ...rest] }) => {

			response += `<br>${first.username}</br>`
		})

		document.querySelector("#presence").innerHTML = response
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
// which authenticates the session and assigns a `:current_user`.
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
