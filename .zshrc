# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Custom Functions (createSSHServer(), createLazyLoadingImage(),  stim(), playRain(), renameFiles(), convertImg(), toJpg(), toWebp())

# Revert preventing the screen from sleeping: sudo pmset -a disablesleep 1

# Aliases
alias python="python3 $@"
alias pip="pip3 $@"
alias webp="cwebp"

alias c='() { if [ $# -eq 0 ]; then code .; else code "$@"; fi }' # Open the current directory in VS Code
alias o='() { if [ $# -eq 0 ]; then open .; else open "$@"; fi }' # Open the current directory

alias pnpx="pnpm dlx $@"
alias dev="pnpm run dev"
alias start="pnpm run start"
alias i="pnpm i"
alias src="source ~/.zshrc"

alias giturl="git config --get remote.origin.url"
alias editzsh="vim ~/.zshrc"

alias stopBeep="echo '#' > ~/beep.sh"
alias startBeep="echo 'afplay /System/Library/Sounds/Hero.aiff' > ~/beep.sh"
alias playRain="while true; do afplay '/Users/osmangund/Documents/twitch/rain-sounds.mp3'; done"

# Pomodoro Timer (work: 60m, rest: 10m)
alias playWorkNotif='osascript -e '\''display notification "Take a break! 🏞️" with title "Work Timer is up!" sound name "Crystal"'\'''
alias playBreakNotif='osascript -e '\''display notification "Get back to work. ⭐️" with title "Break is over!" sound name "Crystal"'\'''
alias work="timer 60m  && playWorkNotif"
alias rest="timer 10m && playBreakNotif"

# Timer 
stim() {
    if [ $# -ne 2 ]; then
        echo "Usage: stim <duration> <message>"
        return 1
    fi

    # Extract the duration and message
    duration=$1
    message=$2

    # Convert duration to seconds
    if [[ $duration == *s ]]; then
        seconds=${duration%s}
    elif [[ $duration == *m ]]; then
        seconds=$(( ${duration%m} * 60 ))
    else
        echo "Invalid duration format. Use <number>s or <number>m."
        return 1
    fi

    # Start the countdown
    echo "Timer set for $duration. Message: $message"
    sleep $seconds

    # Alert loop
    while true; do
        echo "$message"
        afplay /System/Library/Sounds/Ping.aiff
        sleep 1
    done
}

renameFiles() {
  if [ $# -ne 1 ]; then
    echo "Usage: rename_files <prefix>"
    return 1
  fi

  prefix=$1
  count=1

  for file in *; do
    [[ -d "$file" ]] && continue
    ext="${file##*.}"
    
    new_name="${prefix}-${count}.${ext}"
    
    # Ensure the new file name does not already exist
    while [ -e "$new_name" ]; do
      ((count++))
      new_name="${prefix}-${count}.${ext}"
    done
    
    mv "$file" "$new_name"
    ((count++))
  done
}

createSSHServer() {
	if [ $# -eq 0 ] || [ $# -gt 1 ]; then
        echo "Usage: createSSHServer <PORTNAME> (eg: 3000 for localhost:3000)"
        return 1
    fi

	ssh srv.us -R "1:localhost:$1"

}

# Create Small Images for Lazy Loading
createLazyLoadingImage() {
    if [ $# -eq  0 ]; then
        echo "Usage: resize_image <input_image_file>"
        return  1
    fi

    for input_image in "$@"; do
        # Check if the file is a JPEG image
        if [[ $input_image == *.jpg ]]; then
            output_image="${input_image%.jpg}-small.jpg"
            ffmpeg -loglevel error -i "$input_image" -vf scale=20:-1 "$output_image"
            echo "Resized image saved as $output_image"
		elif [[ $input_image == *.webp ]]; then
			output_image="${input_image%.webp}-small.webp"
			ffmpeg -loglevel error -i "$input_image" -vf scale=20:-1 "$output_image"
			echo "Resized image saved as $output_image"
        elif [[ $input_image == *.png ]]; then
            output_image="${input_image%.png}-small.png"
            ffmpeg -loglevel error -i "$input_image" -vf scale=20:-1 "$output_image"
            echo "Resized image saved as $output_image"
		else
            echo "Skipping non-image file: $input_image"
        fi
    done
}

# Convert images to WEBP format
toWebp() {
    if [[ $# -eq 0 ]]; then
        echo "Usage:"
        echo "  Single file conversion: toWebp filename"
        echo "  Mass conversion: toWebp file1 [file2 ...]"
        return 1
    fi

    # Nested function to convert a single file to WebP
    convert_to_webp() {
        local input_file="$1"

        if [[ ! -f "$input_file" ]]; then
            echo "Error: File '$input_file' not found."
            return 1
        fi

        # Extract the file extension and convert to lowercase
        local file_extension="${input_file##*.}"
        file_extension="${file_extension:l}"  # Convert to lowercase (Zsh syntax)
        local file_name="${input_file%.*}"
        local webp_output="${file_name}.webp"

        if [[ "$file_extension" == "webp" ]]; then
            echo "Error: File '$input_file' is already in WebP format."
            return 1
        fi

        cwebp -q 80 "$input_file" -o "$webp_output"
        
        if [[ $? -eq 0 ]]; then
            echo "File '$input_file' converted to '$webp_output' successfully."
        else
            echo "Error converting '$input_file' to WebP format."
            return 1
        fi
    }

    # Function to handle directories
    handle_directory() {
        local dir="$1"
        # Count the number of files in the directory
        local file_count
        file_count=$(find "$dir" -type f | wc -l)

        if (( file_count > 1 )); then
            echo "The directory '$dir' contains $file_count files. Do you want to convert all images in this directory? (y/n)"
            read -r response
            if [[ "$response" == "y" ]]; then
                # Find all files in the directory and attempt to convert them
                find "$dir" -type f | while read -r file; do
                    convert_to_webp "$file"
                done
            else
                echo "Skipping directory '$dir'."
            fi
        else
            echo "The directory '$dir' has only one file or none, skipping prompt."
            # Automatically attempt to convert if there's one file
            find "$dir" -type f | while read -r file; do
                convert_to_webp "$file"
            done
        fi
    }

    # Loop through all provided arguments
    for input in "$@"; do
        if [[ -d "$input" ]]; then
            # If the input is a directory, check the number of files and handle accordingly
            handle_directory "$input"
        else
            # Otherwise, treat it as a file and attempt to convert
            convert_to_webp "$input"
        fi
    done
}


# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="random"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# pnpm
export PNPM_HOME="/Users/osmangund/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
