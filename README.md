<div align="center">
 
![popit](https://github.com/user-attachments/assets/b7cd3092-3075-4d1a-ab6d-5abbbc23f681)

</div>

# pop it!

**pop it!** is a fun and addictive game developed using the Godot Engine.

<div align="center">

https://github.com/user-attachments/assets/62f213b8-35ba-4ed5-b3a6-b505167af995

</div>

## Game Modes

- **Arcade**: Classic bubble-popping fun with progressively challenging levels.
- **Arcade+**: An enhanced version of Arcade with more dynamic gameplay.
- **Memory**: A challenging mode that tests your memory as you pop bubbles in a specific order.
- **Fidget**: A relaxing mode to freely pop bubbles at your own pace.

## Download

You can download the latest release of **pop it!** for various platforms:

[![Release](https://img.shields.io/github/release/serifpersia/pop-it.svg?style=flat-square)](https://github.com/serifpersia/pop-it/releases)

## Building from Source

If you'd like to build **pop it!** from source, follow these steps:

### Requirements

- Ensure you have [Godot Engine 4.3](https://godotengine.org/download) or above installed.
- You will also need the following addon:
  - [Discord-RPC](https://github.com/vaporvee/discord-rpc-godot/releases)

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/serifpersia/pop-it.git
   cd pop-it
2. **Addons Installation**:
   - Download the addons and extract the zip files into the `addons` directory of your Godot project.
   - Your folder structure should look like this:
     ```
     pop-it/
     └── addons/
         ├── discord-rpc-gd/
     ```

3. **Configuration**:
   - For the Discord-RCP addon, enable it by navigating to `Project Settings > Plugins` in Godot.

4. **Directory Setup**:
   - If the `addons` directory does not exist, create it manually.
   - Note that this directory is included in the `.gitignore` by default to keep the repository as clean as possible. You will need to create this directory and add the necessary addons yourself.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

