#!/usr/bin/env bash

for kickstart in sample sample_end legacy ; \
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
