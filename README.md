# Redmine Login Attempts Limit

Login attempts limit plugin for Redmine

![Redmine Plugin Version](https://img.shields.io/badge/Redmine_Plugin-v1.0.3-red) ![Redmine Version](https://img.shields.io/badge/Redmine-v5.0.z-blue) ![Language Support](https://img.shields.io/badge/Languages-en,_de-green) ![Version Stage](https://img.shields.io/badge/Stage-release-important) ![develop](https://github.com/xmera-circle/redmine_login_attempts_limit/actions/workflows/5-0-stable.yml/badge.svg)

The Redmine Login Attempts Limit plugin is a Redmine plugin. It blocks login attempts after x trials for y minutes.

—

![Access blocked](https://circle.xmera.de/attachments/download/259/clipboard-202301171504-bxsd7.png)

## Usage example

Navigate to the plugin settings `Administration » Configuration » Plugins » Login Attempts Limit` and edit the default settings if required.

For more examples and usage, please refer to the [official documentation](https://circle.xmera.de/projects/redmine-login-attempts-limit/wiki).

### Dependencies

To run the plugin you need the following dependencies installed:

* [Redmine 5.0.z](https://github.com/redmine/redmine)
* [Advanced Plugin Helper 0.4.z](https://github.com/xmera-circle/advanced_plugin_helper)

## Installation

> :warning: **Don't clone the default branch**: For production you need to clone the **_master_** branch explicitly!

```shell

git clone -b master https://github.com/xmera-circle/redmine_login_attempts_limit

```

You need a running Redmine instance in order to install the plugin. If you need help with the installation, please refer to [Redmine.org](https://redmine.org).

Instructions for the installation of this plugin can be found in the [official documentation](https://circle.xmera.de/projects/redmine-login-attempts-limit/wiki) on
[xmera Circle - the community website of xmera](https://circle.xmera.de).

After placing the plugin in the Redmine `plugins` directory, install bundle dependencies in the Redmine root:

```bash
cd /path/to/redmine
bundle install --without development test
```

If you intend to run multiple Redmine processes that share lock state via `Rails.cache`, ensure you configure a Redis cache in your Redmine production environment (see `docs/REDIS_SETUP.md`).

## Changelog

All notable changes to this plugin will be reported in the [changelog](https://circle.xmera.de/projects/redmine-login-attempts-limit/repository/redmine_login_attempts_limit/entry/CHANGELOG.md).

## Maintainer

This project is maintained by xmera Solutions GmbH.

## Context Information

This plugin is part of a plugin selection aiming to provide the information security management system solution xmera Omnia.

All plugins in the selection are compatible with [Redmine](https://redmine.org) version 4 and higher.

More information about xmera Omnia can be found at [xmera](https://xmera.de).

### Notes about recent changes by Mattani

* Lock status storage: The plugin was modified to store lock/invalid-account status in `Rails.cache` (instead of in-process memory) so multiple Redmine processes can share lock state.
* Test environment: the plugin was tested on RedMica 3.2.4.stable (based on Redmine 6.0.6.devel).
* Advanced Plugin Helper: the upstream `Advanced Plugin Helper 0.4.z` is not compatible with Redmine 6; this repository uses a forked helper at [kid2407/advanced_plugin_helper](https://github.com/kid2407/advanced_plugin_helper) for Redmine 6 compatibility.
* Note: Sharing lock state across multiple processes requires a shared cache (e.g. Redis).

## Support

For any question on the usage of this plugin please use the [xmera Circle » Community Portal](https://circle.xmera.de). If you found a problem with the software, please create an issue on [xmera Circle](https://circle.xmera.de) or [GitHub](https://github.com/xmera-circle/redmine_login_attempts_limit).

If you are a xmera Solutions customer you may alternatively forward your issue to the xmera Service Customer Portal.

## Security

xmera Solutions takes the security of our software products seriously.

If you believe you have found a security vulnerability in any xmera Solutions-owned repository, please report it to us as described in the [SECURITY.md](/SECURITY.md).

## Code of Conduct

We pledge to act and interact in ways that contribute to an open, welcoming, diverse, inclusive, and healthy community.

Please read our [Code of Conduct](https://circle.xmera.de/projects/contributors-guide/wiki/Code-of-conduct) to make sure that you agree to follow it.

## Contributing

Your contributions are highly appreciated. There are plenty ways [how you can help](https://circle.xmera.de/projects/contributors-guide/wiki).

In case you like to improve the code, please create a pull request on GitHub. Bigger changes need to be discussed on [xmera Circle » Community Portal](https://circle.xmera.de) first.

## History

The original author of the plugin is midnightSuyama <https://github.com/midnightSuyama/redmine_login_attempts_limit>. He stopped maintaining the plugin in 2017.

Stefan Zieger maintained it in 2020 but also stopped to contribute to the community. We forked the plugin from Stefan Zieger <https://github.com/RegioHelden/redmine_login_attempts_limit>.

Many thanks to the author and contributors for their important work to make
Redmine a little bit safer!

### Recent changes

* 2025: Mattani updated the plugin to store lock/invalid-account status in `Rails.cache` to support multi-process Redmine setups and adjusted tests to target RedMica/Redmine 6.

## License

Copyright &copy; 2025 Mattani (<https://github.com/Mattani>).  
Copyright &copy; 2021-2023 Liane Hampe (<liaham@xmera.de>), xmera Solutins GmbH.  
Copyright &copy; 2020 Stefan Zieger (<https://github.com/saz>), Regio Helden.  
Copyright &copy; 2016-2017 midnightSuyama (<https://github.com/midnightSuyama>).  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
