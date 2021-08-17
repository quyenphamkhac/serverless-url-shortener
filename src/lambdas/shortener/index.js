exports.handler = async (event, context, callback) => {
  console.log("Received event: ", event);
  var data = {
    greetings: "Hello, I'm shortener",
  };
  callback(null, data);
};
