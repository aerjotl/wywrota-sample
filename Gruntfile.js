module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      },
      all_stuff: {
        files: [{
            expand: true,
            cwd: 'resources/js',
            src: '**/*.js',
            dest: '../static/js'
        }]
      },
      compress_js: {
        files: {
          '../static/js/_main.js': [
              'resources/js/jquery/jquery-1.7.1.min.js',
              'resources/js/fancybox/jquery.fancybox-1.3.1.js',
              'resources/js/autogrow/jquery.autogrow-textarea.js',
              'resources/js/vote/jquery.rating.js',
              'resources/js/jquery/collapse/collapse.js',
              'resources/js/main/utils.js',
              'resources/js/main/jsf-validation.js',
              'resources/js/jquery/jquery.hoverIntent.js',
              'resources/js/jquery/idTabs/idTabs.pack.js',
              'resources/js/jquery/unveil/jquery.unveil.min.js',
              'resources/js/jquery/fluidVideo/fluid.js',
              'resources/js/cluetip/jquery.cluetip.js',
              'resources/js/main/jsf-main.js',
              'resources/js/facebook-api.js',
              'resources/js/jquery/swfobject/jquery.swfobject.1-1-1.js',
              'resources/js/jquery/dateinput/date_input.js',
              'resources/js/jquery/wyw/maxInt.js'
          ],
          '../static/js/_forms.js': [
              'resources/js/jquery/dateinput/date_input.js',
              'resources/js/jquery/wyw/maxInt.js'
          ],
          '../static/js/_audio_record.js': [
              'resources/js/audio-record/audiodisplay.js',
              'resources/js/audio-record/recorder.js',
              'resources/js/audio-record/main.js'
          ]
        }
      }
    },

    cssmin: {
      options: {
        shorthandCompacting: false,
        roundingPrecision: -1
      },
      group_main: {
        files: {
          '../static/css/_main.css': [
              'resources/css/content.css',
              'resources/css/layout.css',
              'resources/css/photos.css',
              'resources/css/messages.css',
              'resources/css/main.css',
              'resources/css/items.css',
              'resources/css/forms.css',
              'resources/css/vote.css',
              'resources/css/usergroups.css',
              'resources/css/socialbar.css',
              'resources/js/fancybox/jquery.fancybox-1.3.1.css',
              'resources/js/fancybox/fancy-wywrota-addons.css',
              'resources/js/cluetip/jquery.cluetip.css',
              'resources/js/jquery/dateinput/date_input.css'
              ]
        }
      },
      others: {
        files: [{
          expand: true,
          cwd: 'resources/css',
          src: ['*.css', '!*.min.css'],
          dest: '../static/css',
          ext: '.css'
        }]
      },
      js_css: {
        files: [{
          expand: true,
          cwd: 'resources/js',
          src: ['*.css', '!*.min.css'],
          dest: '../static/js'
        }]
      }

    },

    copy: {
      main: {
        files: [
          { 
            cwd: 'resources/', 
            src: [
              '**', '!css/**', '!pliki/**'
            ], 
            dest: '../static/', 
            expand: true,
            dot: true
          }
        ]
        
      },
    },

    symlink: {
      options: {
        overwrite: false
      },
      explicit: {
        src: '../files/pliki',
        dest: '../static/pliki'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-symlink');


  grunt.registerTask('quick', [
    'copy:main',
    'uglify:compress_js', 
    'cssmin:group_main', 
    'cssmin:others' 
  ]);



  grunt.registerTask('default', [
    'quick', 

    // uglify everything from js subfolders
    'uglify:all_stuff', 
    'cssmin:js_css', 

    // create symlinks when needed
    'symlink:explicit'
  ]);

};