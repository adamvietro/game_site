let KeyInput = {
    mounted() {
      window.addEventListener("keydown", (e) => {
        if (/^[a-zA-Z]$/.test(e.key)) {
          this.pushEvent("add_letter", { letter: e.key.toLowerCase() });
        } else if (e.key === "Backspace") {
          this.pushEvent("delete_letter", {});
        }
      });
    },
    destroyed() {
      // Clean up event listener to avoid memory leaks
      window.removeEventListener("keydown", this.handleKeydown);
    }
  };
  
  export default KeyInput;