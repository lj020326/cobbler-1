FROM centos:7

#MAINTAINER Didier FABERT (tartare) <didier@tartarefr.eu>
MAINTAINER Lee Johnson <lj020326@gmail.com>

# RPM REPOs
RUN yum install -y \
    epel-release \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN yum update -y \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN yum install -y \
  python2-django16 \
  cobbler \
  cobbler-web \
  pykickstart \
  debmirror \
  curl wget \
  rsync \
  supervisor \
  net-tools \
  memtest86+ \
  which \
  && yum clean all \
  &&  rm -rf /var/cache/yum

#RUN yum swap -y python2-django python2-django16

# Copy supervisor conf
COPY supervisord/supervisord.conf /etc/supervisord.conf
COPY supervisord/cobblerd.ini /etc/supervisord.d/cobblerd.ini
COPY supervisord/tftpd.ini /etc/supervisord.d/tftpd.ini
COPY supervisord/httpd.ini /etc/supervisord.d/httpd.ini

# Copy personnal snippets
COPY snippets/partition_config /var/lib/cobbler/snippets/partition_config
COPY snippets/configure_X /var/lib/cobbler/snippets/configure_X
COPY snippets/add_repos /var/lib/cobbler/snippets/add_repos
COPY snippets/disable_prelink /var/lib/cobbler/snippets/disable_prelink
COPY snippets/systemd_persistant_journal /var/lib/cobbler/snippets/systemd_persistant_journal
COPY snippets/rkhunter /var/lib/cobbler/snippets/rkhunter
COPY snippets/enable_X /var/lib/cobbler/snippets/enable_X
COPY snippets/yum_update /var/lib/cobbler/snippets/yum_update

# Copy personnal kickstart

# Use personnal snippets
RUN for kickstart in sample sample_end legacy ; \
    do \
        additional_post_snippets="" ; \
        for snippet in \
                        add_repos \
                        disable_prelink \
                        systemd_persistant_journal \
                        rkhunter \
                        enable_X \
                        yum_update ; \
        do \
          additional_post_snippets="${additional_post_snippets}\n\$SNIPPET('${snippet}')" ; \
        done ; \
        sed -i \
           -e "/post_anamon/ s/$/${additional_post_snippets}/" \
           -e "/^autopart/ s/^.*$/\$SNIPPET('partition_config')/" \
           -e "/^skipx/ s/^.*$/\$SNIPPET('configure_X')/" \
       /var/lib/cobbler/kickstarts/${kickstart}.ks ; \
    done

## Install vim-enhanced by default and desktop packages if profile have el_type set to desktop (ksmeta)
RUN echo -e "@core\n\nvim-enhanced\n#set \$el_type = \$getVar('type', 'minimal')\n#if \$el_type == 'desktop'\n@base\n@network-tools\n@x11\n@graphical-admin-tools\n#set \$el_version = \$getVar('os_version', None)\n#if \$el_version == 'rhel6'\n@desktop-platform\n@basic-desktop\n#else if \$el_version == 'rhel7'\n@gnome-desktop\n#end if\n#end if\nkernel" >> /var/lib/cobbler/snippets/func_install_if_enabled

COPY first-sync.sh /usr/local/bin/first-sync.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh /usr/local/bin/first-sync.sh

EXPOSE 69 80 443 25151

VOLUME [ "/var/www/cobbler", "/var/lib/tftp", "/var/lib/cobbler/config", "/var/lib/cobbler/backup", "/var/run/supervisor", "/mnt" ]

ENTRYPOINT /entrypoint.sh
