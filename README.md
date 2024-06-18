```
    ✯                              .°•    |
    __     °    •                __      / \
   / /   ____ ___  ______  _____/ /_    | O |
  / /   / __ `/ / / / __ \/ ___/ __ \   | O |
 / /___/ /_/ / /_/ / / / / /__/ / / /  /| | |\
/_____/\__,_/\__,_/_/ /_/\___/_/ /_/  /_(.|.)_\
```

This is my personal neovim config built on top of LunarVim's [Launch.nvim](https://github.com/LunarVim/Launch.nvim) (some mid-2023 version)

Keep in mind that a bunch of keymaps won't work for you out of the box as they're based on my hammerspoon config. I might commit it later.

## Some features

- My keymaps are specific. I come from VSCode on Mac and I really like the CMD-based keymaps, so I brought them here (with hammerspoon). I also disabled a bunch of the default one-key mappings - judge me if you want 😛.
- You can make an `alias lg="NVIM_USER_PARAMS=--git vim"` in your .zshrc to use the builtin `submodules.nbim` plugin (based on telescope + lazygit). It opens lazygit by default, but if you have submodules - you'll get an overview of all changes (similar to GIT tab in VSCode)

## And stuff

Below is a shortened version of the original README.md:

Copy/paste fix:

- On mac `pbcopy` should be builtin

- On Ubuntu

  ```sh
  sudo apt install xsel # for X11
  sudo apt install wl-clipboard # for wayland
  ```

Node & Python support

- Neovim python support

  ```sh
  pip install pynvim
  ```

- Neovim node support

  ```sh
  npm i -g neovim
  ```

`ripgrep` is needed for Telescope to work:

- Ripgrep

  ```sh
  sudo apt install ripgrep
  ```
