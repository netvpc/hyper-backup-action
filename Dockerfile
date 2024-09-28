# Builder stage
FROM netvpc/hyper-backup-action:base AS builder

COPY templates /templates
COPY main.sh /usr/bin/
ENTRYPOINT [ "tini", "--" ]
CMD ["main.sh"]
