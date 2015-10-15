<h2>
<a name="installation" class="anchor" href="#installation"><span class="octicon octicon-link"></span></a>Installation</h2>

<p>First, make sure you have Ruby installed.</p>

<p><strong>On a Mac</strong>, open <code>/Applications/Utilities/Terminal.app</code> and type:</p>

<pre><code>ruby -v
</code></pre>

<p>If the output looks something like this, you're in good shape:</p>

<pre><code>ruby 1.9.3p484 (2013-11-22 revision 43786) [x86_64-darwin13.0.0]
</code></pre>

<p>If the output looks more like this, you need to <a href="http://www.ruby-lang.org/en/downloads/">install Ruby</a>:</p>

<pre><code>ruby: command not found
</code></pre>

<p><strong>On Linux</strong>, for Debian-based systems, open a terminal and type:</p>

<pre><code>sudo apt-get install ruby-dev
</code></pre>

<p>or for Red Hat-based distros like Fedora and CentOS, type:</p>

<pre><code>sudo yum install ruby-devel
</code></pre>

<p>(if necessary, adapt for your package manager)</p>

<p><strong>Windows</strong>, is not supported for now.</p>

<p>Once you've verified that Ruby is installed:</p>

<pre><code>gem install docman</code></pre>