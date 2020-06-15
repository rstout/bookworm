import bookworm from 'ic:canisters/bookworm';

bookworm.greet(window.prompt("Enter your name:")).then(greeting => {
  window.alert(greeting);
});
