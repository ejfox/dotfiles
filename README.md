# Usage Instructions

1. Clone your dotfiles repository (if you haven't already):
   ```
   git clone https://github.com/ejfox/dotfiles.git ~/.dotfiles
   ```

2. Create a symlink for your .tmux.conf:
   ```
   ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
   ```

3. Pull the latest changes:
   ```
   cd ~/.dotfiles
   git pull origin main
   ```

Now, to keep things synced going forward, you can just run `git pull` in your ~/.dotfiles directory whenever you want to update.

If you want to automate this process, you could create a simple script:



```bash
#!/bin/bash

# File: ~/sync-dotfiles.sh

# Navigate to dotfiles directory
cd ~/.dotfiles

# Pull latest changes
git pull origin main

# Re-create symlink (in case the file was added recently)
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf

echo "Dotfiles synced successfully!"

```

Save this script as `~/sync-dotfiles.sh`, make it executable with `chmod +x ~/sync-dotfiles.sh`, and you can run it anytime with `~/sync-dotfiles.sh`.

To handle potential conflicts between your local .tmux.conf and the one in the repository:

1. If you've made local changes you want to keep:
   ```
   cp ~/.tmux.conf ~/.dotfiles/.tmux.conf
   cd ~/.dotfiles
   git add .tmux.conf
   git commit -m "Update .tmux.conf"
   git push origin main
   ```

2. If you want to discard local changes and use the version from the repo:
   ```
   cd ~/.dotfiles
   git checkout .tmux.conf
   ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
   ```

This approach gives you a quick and easy way to sync your tmux config (and other dotfiles) across machines. It's not as automated as some of the more complex setups we discussed earlier, but it's straightforward and gets the job done.

Remember, whenever you make changes to your .tmux.conf that you want to sync across machines:

1. Make the changes in ~/.dotfiles/.tmux.conf
2. Commit and push the changes
3. On other machines, run the sync script or `git pull` in the ~/.dotfiles directory