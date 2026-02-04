# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export DISABLE_LAST_LOGIN=1
export PATH=$PATH:~/.spoofdpi/bin
alias build="pnpm run build"
alias ag="antigravity $@"
alias aga="antigravity ."
# Aliases
alias portkill="killport $@"
alias pk="killport $@"
alias python="python3 $@"
alias pip="pip3 $@"
alias webp="cwebp"
alias t="npx tsc --noEmit"
alias c='() { if [ $# -eq 0 ]; then code .; else code "$@"; fi }' # Open the current directory in VS Code
alias o='() { if [ $# -eq 0 ]; then open .; else open "$@"; fi }' # Open the current directory

alias pnpx="pnpm dlx $@"
alias dev="pnpm run dev"
alias start="pnpm run start"
alias i="pnpm i"
alias src="source ~/.zshrc"

alias giturl="git config --get remote.origin.url"
alias editzsh="vim ~/.zshrc"

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
            # Disabled
            echo "Input has a directory: $input. Please use files instead."
            # handle_directory "$input"
        else
            # Otherwise, treat it as a file and attempt to convert
            convert_to_webp "$input"
        fi
    done
}
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/Users/emregnd/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

killport () {
  if [ -z "$1" ]; then
    echo "❌ Please provide a port number"
    return 1
  fi

  lsof -ti :$1 | xargs kill -9 2>/dev/null

  echo "✅ Killed process on port $1"
}


# Added by Antigravity
export PATH="/Users/emregnd/.antigravity/antigravity/bin:$PATH"
