exports.handler = function (event, context, callback) {
  console.log("Received event: ", event);
  var data = {
    greetings: "Hello, I'm redirector",
  };
  callback(null, data);
};
