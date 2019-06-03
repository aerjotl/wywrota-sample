This repository contains only an incomplete sample of the project. It does not contain templates, css files nor other static resouces, which are stored in another private repository.

# Pan Wywrotek

Pan Wywrotek is a content managment system used for managing Wywrota.pl website.

### Code structure

- `cgi-bin` -  Perl FastCGI scripts, project libraries and configuration files
- `doc` - some documentation and project history
- `resources` - static files - JavaSctipt, images, fonts etc.
- `templates` - site templates in [Template-Toolkit](http://search.cpan.org/~abw/Template-Toolkit-2.27/lib/Template.pm) format
- `test` - test data for incoming interfaces
- `utils` - various perl and bash scripts


### Setting up development environment

You can follow this steps to set up local development environment on Linux/Mac/Windows.
This setup is slightly different than production environment.

1. Clone sources from Git
   ``` 
   git clone git@bitbucket.org:wywrota/wywrotek.git
   ```
   
2. Install Apache, MySQL, Perl, NodeJS, Grunt
    - on Linux use standard system packages
    - on Mac use Xcode
    - on Windows you can use [WAMP](http://www.wampserver.com/en/#download-wrapper) 
      and [ActivePerl](http://www.activestate.com/activeperl)
    - on Windows create folder `C:\usr\bin\` and copy there `perl.exe` file to allow cross-platform cgi scripts

3. Set environment variable `WYWROTEK_SITE_CONFIG` (ie. `windows`, `mac`, `dev`)
   ```sh
   export WYWROTEK_SITE_CONFIG=mac
   ```
   
4. Edit file `./config/config.xml`. In the section `<mode name="mac">` set all necessary paths and passwords.  

5. Install required Perl libaries.    The script `./utils/list_dependencies.pl` will get the full list of missing dependencies for you. It gives you a command you should run to install the modules returned by the script, ie:
   ```
   sudo cpan  Astro::MoonPhase CGI::Ajax CGI::Fast Cache::Memcached ...
   ```
   - In case of problems with installing  MySQL libraries on Windows use the package manager provided by ActivePerl `Start > Active State Perl > Perl Package Manager`, search for `dbd-mysql` and install.
   - In case of problems with C++ compilier on windows `'dmake' is not recognized as an internal or external command` install [MinGW](http://www.mingw.org/)

6. Import database. You will need production or development dapabase dump. To import the database you can use the script `utils/import_db.sh`
 
7. Verify installation by running `perl cgi-bin/db.fcgi`. You should see a message `"Status: 302 Found  Location: http://www.wywrota.pl"` or similar.

8. Set up Apache. In the file `conf\httpd.conf` make the following changes:
   - uncomment `LoadModule rewrite_module libexec/apache2/mod_rewrite.so`
   - uncomment `LoadModule cgi_module libexec/apache2/mod_cgi.so`
   - copy the file `wywrota-apache-mac.conf` to apache conf directory and adjust the paths in this file
   - add `Include /conf/wywrota-apache-mac.conf`  at the end of the `conf\httpd.conf` file

9. Edit the `hosts` file. It can be found in the following locations `/etc/hosts` or `%systemroot%\system32\drivers\etc\hosts`. 
   Add the following lines
   ```
   127.0.0.1		wywrota.local
   127.0.0.1		www.wywrota.local
   127.0.0.1		teksty.wywrota.local
   127.0.0.1		literatura.wywrota.local
   ```

10. Install Grunt CLI and generate static files
    ```
    npm install -g grunt-cli
    npm install
    grunt
    ```

11. Restart Apache. After accessing `http://www.wywrota.local/` you should see the home page.


### Debugging

To enable debugging you need to adjust `<debug_level>` parameter in `config.xml` file.
You can set it to one of the following values: "all, trace, debug, warn, error, none"

Use the following functions to add debugging points to your code:
```
Wywrota->trace("Starting to load data");
Wywrota->debug("You can pass objects too", $object);
Wywrota->warn("Something went wrong with this file", $file);
Wywrota->error("Something went really wrong with this file!", $file);
```


