<h2>Quickstart</h2>
<h3>Example 1:</h3>
<ul>
	<li>Multisite environment</li>
	<li>Two websites</li>
	<li>Drupal 7</li>
	<li>Acquia hosting as target</li>
</ul>
<h4>Step 1: Directory structure creation</h4>
<p>The important thing to understand - Docman doesn't really care about your directory structure, it scans your master directory for subdirectories and config files and then it will build what you want him to build. In this example we are replicating Acquia docroot structure, but feel free to adapt it to your needs.</p>
<p>This is why the tool is Drupal-version agnostic, you can easily adapt your Drupal 8 websites, because it is you who decide how to build the docroot, not Docman.</p>
<p>First of all you will need a config repository for this configuration. For now, you can just use local repositories, but just use external git links when you're ready. First, lets create a config repository:</p>
<pre><code>mkdir docroot-config
</code></pre>
<p>Lets init a git repository:</p>
<pre><code>cd docroot-config; git init
</code></pre>
<p>We now have a local git repository, lets create an initial directory structure and config file:</p>
<pre><code>$ mkdir master</code></pre>
<p>Then we will need your common modules for all the projects:</p>
<pre><code>$ mkdir master/common</pre></code>
<p>Then we will need a directory for Drupal core :</p>
<pre><code>$ mkdir master/docroot </pre></code>
<p>Then we will need an empty profiles directory:</p>
<pre><code>$ mkdir master/profiles </pre></code>
<p>Then we will need a projects directory, where all your websites will go:</p>
<pre><code>$ mkdir master/projects </pre></code>
<p>Then we will need a project 1 directory</p>
<pre><code>$ mkdir master/projects/project1 </pre></code>
<p>Then we will need a project 2 directory:</p>
<pre><code>$ mkdir master/projects/project2 </pre></code>
<p>Then we will need sites repository, which basically represents Drupal default /sites directory:</p>
<pre><code>$ mkdir master/sites </pre></code>
<h4>Step 2: main config file creation</h4>
<p>Config files are important files that Docman uses in order to understand what kind of content the directory contain, where he should take the code, and what to run after along with environments.<p>
<p>Config files are .yaml files</p>
<p>The most important configuration file is config.yaml, which is located in the root of the config repository, lets create it:</p>
<pre><code>$ touch config.yaml</pre></code>
<p>Now lets fill it with basic config that suits our needs:</p>
<pre><code>---
environments:
  dev:
    deploy_target: git_target
    state: development
    target_checker:
      handler: :ssh
      file_path: /mnt/www/html/docman1.dev
      ssh_host: xxxxxxxx.devcloud.hosting.acquia.com 
      ssh_user: docman1 # Edit this!
  test:
    deploy_target: git_target
    state: staging
    target_checker:
      handler: :ssh
      file_path: /mnt/www/html/docman1.test
      ssh_host: xxxxxxxxx.prod.hosting.acquia.com
      ssh_user: docman1 # Edit this!
  prod:
    deploy_target: git_target
    state: stable
    tagger:
      enabled: true
      handler: :option
</pre></code>
<p>Please note the structure, here we define the list of environments. You can have as many environments as you need, but here you see the default Acquia hosting structure with 3 environments, all of them are managed by git. Variables are pretty self explanatory:</p>
<pre>deploy_target: git_target</pre>
<p>This is important to say to docman, it set the environment to be built and pushed to git.</p>
<pre>state: development</pre>
<p>This is the name that you will use for docman build command.</p>
<pre>target_checker: </pre>
<p>Important part to say to docman about how to check if the code was correctly deployed. In this case after each push to git the tool will use the following parameters to connect to the environnement and check if the code is in place.</p>
<pre>handler: :ssh </pre>
<p>We are using ssh protocol to check</p>
<pre>file_path: :ssh </pre>
<p>Where to look for deployed files</p>
<pre>ssh_host:xxxxxxx.devcloud.hosting.acquia.com </pre>
<p>SSH host. Put the one that is shown to you in your hosting dashboard</p>
<pre>ssh_user:docman1 </pre>
<p>SSH user</p>
<pre>tagger: </pre>
<p>Subsystem for production environment, create stable docroot tags by checking all the stable tags from all the repositories and merging them into one.</p>
<pre>enabled: true</pre>
<p>Enabling the tagger</p>
<pre>handler: option </pre>
<p>@Todo: description</p>
<p>As you can see, your environments can be anywhere, you do not need to stick to the same hosting system, you can get the code from your local development server dev environment and your staging environment will be in the real hosting. Continuous integration!

<h4>Step 3: Common files config file creation</h4>
<p>In this example we have common modules reposiroty which resides in master/common directory. Lets create a config file for it:</p>
<pre><code>$ touch master/common/info.yaml</pre></code>
<p>We are using info.yaml here instead of config.yaml, because docman will search for info.yaml files in each directory to get its config.</p>
<p>Now lets put the basic configuration inside:</p>
<pre><code>status: enabled
type: repo
repo: /Users/Adyax/Code/docman-common-test/
order: 30
states:
  development:
    type: branch
    version: develop
  staging:
    type: branch
    version: master
  stable:
    source:
      type: :retrieve_from_repo
      repo: :project_repo
      branch: state_stable
      file: info.yaml
hooks:
  builder:
    after_execute:
      - type: :script
        location: $INFO$/after_build.sh
        execution_dir: $PROJECT$
        params:
          - environment
</pre></code>
<p>Again, see below the quick explanation of what is what here. The config file consists of main settings and states part, states are needed to describe to docman from which part of repository it needs to get the code to build for the specific environment (see config.yaml for the list of environments):</p>
<pre>type: repo</pre>
<p>Docman needs to know where to look for the code. This time it is a git repository.</p>
<pre>repo: /Users/Adyax/Code/docman-common-test/</pre>
<p>Git URL which you normally use in git clone command. In this example - local repository.</p>
<pre>order: 30</pre>
<p>The order in which docman builder gets this repository</p>
<pre>states: </pre>
<p>Starts the states description part</p>
<pre>development: </pre>
<p>The state that correspond to the environment in the main config.yaml file</p>
<pre>type: branch</pre>
<p>Which branch from the original repository should be taken for this state</p>
<pre>version: develop</pre>
<p>Ddevelop branch for development state in development environment in this example</p>
<pre>stable:</pre>
<p>Starts the stable part for this state</p>
<pre>source:</pre>
<p>Starts the source description for the stable version</p>
<pre>type: :retrieve_from_repo</pre>
<p>In this example it will get the information from the same repository. But guess what - you can get it from other places too, like a specific file somewhere.</p>
<pre>repo: :project_repo</pre>
<p>Says that we are using the same repository as defined in the beginning of the file</p>
<pre>branch: state_stable</pre>
<p>Says that we are using the branch state_stable to get the release information (the name of the stable tag for this reposiroty)</p>
<pre>file: info.yml</pre>
<p>The file in which docman will search for the stable tag name for this repository. Ex. v.0.0.2</p>
<pre>hooks: </pre>
<p>Starts the hooks part that we be run during the build</p>
<pre>builder: </pre>
<p>Starts the builder configuration part</p>
<pre>after: </pre>
<p>Starts the hooks part that we be run during the build</p>
<p>Docman will also search for after_build.sh file, which contains the list of operations to fire after the build is finished:</p>
<pre><code>$ touch master/common/after_build.sh</code></pre>
<p>Put the following content in it:</p>
<pre><code>#!/bin/sh

set -vx

# Add following files into local git ignore only
if [ "$1" == "local" ]; then
  if [ -f .git/info/exclude ]; then
    rm .git/info/exclude
  fi
  echo "info.yaml" > .git/info/exclude
fi

set +vx</code></pre>

<h4>Step 4: Drupal core config file creation</h4>
<p>In this example we have drupal core repositoty which resides in master/docroot directory. Lets create a config file for it:</p>
<pre><code>$ touch master/docroot/info.yaml</code></pre>
<p>The structure of the config file for this repository is the same as in step 3 ((do not forget to put a proper git link into repo variable)):</p>
<pre><code>type: repo
repo: /Users/Adyax/Code/Adyax/docman-core-test/ 
order: 1
states:
  development:
    type: branch
    version: master
  staging:
    type: branch
    version: master
  stable:
    type: branch
    version: master
hooks:
  builder:
    after_execute:
      - type: :script
        location: $INFO$/after_build.sh
        execution_dir: $PROJECT$
        params:
          - environment
</code></pre>

<h4>Step 5: Profiles config file creation</h4>
<p>In this example we have profiles directory empty, and it resides in master/docroot directory. Lets create a config file for it:</p>
<pre><code>$ touch master/profiles/info.yaml</code></pre>
<p>We do not have anything to put here, so lets disable this directory for docman. Put the following into this file:</p>
<pre><code>status: disabled
type: dir
</code></pre>

<h4>Step 6: Project directories config file creation</h4>
<p>We have two projects (websites), so lets create two subfolders:</p>
<pre><code>$ mkdir master/docroot/project1
$ mkdir master/docroot/project2</code></pre>
<p>And config files for them:</p>
<pre><code>$ touch master/docroot/project1/info.yaml
$ touch master/docroot/project2/info.yaml</code></pre>
<p>The structure of config file for each repository is the same as in step 3, but this time time we will add deployer configuration.  Put this into the configuration files you have just created (do not forget to put a proper git link into repo variable):</p>
<pre><code>type: repo
repo: /Users/Adyax/Code/Adyax/docman-project1-test/
states:
  development:
    type: branch
    version: develop
  staging:
    type: branch
    version: master
  stable:
    source:
      type: :retrieve_from_repo
      repo: :project_repo
      branch: state_stable
      file: info.yaml
hooks:
  builder:
    after_execute:
      - type: :script
        location: $INFO$/after_build.sh
        execution_dir: $PROJECT$
        params:
          - environment
  deployer:
    before_deploy:
      - type: :script
        location: $PROJECT$/tools/deploy/common/before/before.sh
        execution_dir: $ROOT$/docroot
        params:
          - environment
      - type: :script
        location: $PROJECT$/tools/deploy/$ENVIRONMENT$/before/before.sh
        execution_dir: $ROOT$/docroot
        params:
          - environment
    after_deploy:
      - type: :script
        location: $PROJECT$/tools/deploy/$ENVIRONMENT$/after/after.sh
        execution_dir: $ROOT$/docroot
        params:
          - environment
      - type: :script
        location: $PROJECT$/tools/deploy/common/after/after.sh
        execution_dir: $ROOT$/docroot
        params:
          - environment

</code></pre>

<h4>Step 7: Sites directory config file creation</h4>
<p>Sites directory represents Drupal default sites/ directory, lets create it and put the proper config file:</p>
<pre><code>$ mkdir master/docroot/sites</code></pre>
<p>And config file:</p>
<pre><code>$ touch master/docroot/sites/info.yaml</code></pre>
<p>The structure of the config file is the same as in step 3. Put this into the configuration file you have just created (do not forget to put a proper git link into repo variable):</p>
<pre><code>status: enabled
type: repo
repo: /Users/Adyax/Code/Adyax/docman-sites-test/
order: 20
states:
  development:
    type: branch
    version: develop
  staging:
    type: branch
    version: master
  stable:
    source:
      type: :retrieve_from_repo
      repo: :project_repo
      branch: state_stable
      file: info.yaml
hooks:
  builder:
    after_execute:
      - type: :create_symlink
        target_dir: master/docroot
      - type: :script
        location: $INFO$/after_build.sh
        execution_dir: $PROJECT$
        params:
          - environment
</code></pre>
<p>Note additional after_execute configuration, we are saying to docman that after getting the repository it needs to create a symlink to sites in master/docroot directory.</p>
<p>Put also the after_build.sh file:</p>
<pre><code>$ touch master/docroot/sites/after_build.sh</code></pre>
<p>With the following content: </p>
<pre><code>#!/bin/sh

PREFIX="<?php"
ENV_PREFIX='$ENVIRONMENT'
echo "$PREFIX" > project1/env.settings.php
echo "$ENV_PREFIX='$1';" >> project1/env.settings.php
cp default/local.settings.default.php project1/local.settings.php
</pre></code>
