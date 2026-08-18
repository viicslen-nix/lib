# Helpers for OCI-container modules: the host option, mkcert registration, and
# Traefik discovery labels.
#
# The Traefik label schema is Traefik's own; the `modules.programs.mkcert`
# option path is a convention shared across these configs.
{lib}: {
  # The `host` option every container declares.
  mkHostOption = default: label:
    lib.mkOption {
      type = lib.types.str;
      inherit default;
      description = "Hostname for ${label}";
    };

  # Register a host with mkcert, when the mkcert module is present *and*
  # enabled. Container modules are discovered independently of it, so the option
  # may legitimately not exist — hence the defaulted path lookup rather than a
  # direct read.
  mkMkcertDomains = config: domains:
    lib.mkIf
    (lib.attrByPath ["modules" "programs" "mkcert" "enable"] false config)
    {inherit domains;};

  # Traefik discovery labels for one container: an HTTP router that redirects to
  # HTTPS, the HTTPS router itself, and the backend service.
  #
  # `port` and `service` are alternatives — give a port to route to the
  # container, or a service name to hand off to an internal Traefik service
  # (`api@internal`). `scheme` is only needed when the backend speaks HTTPS.
  #
  # Does not include `--network=local`; callers prepend it, so a container that
  # needs other flags before its labels (a `--device`, say) can order them.
  mkTraefikLabels = {
    name,
    host,
    port ? null,
    scheme ? null,
    service ? null,
  }:
    [
      "--label=traefik.enable=true"
      "--label=traefik.http.middlewares.${name}-https-redirect.redirectscheme.scheme=https"
      "--label=traefik.http.middlewares.${name}-https-redirect.redirectscheme.permanent=true"
      "--label=traefik.http.routers.${name}-http.rule=Host(`${host}`)"
      "--label=traefik.http.routers.${name}-http.entrypoints=web"
      "--label=traefik.http.routers.${name}-http.middlewares=${name}-https-redirect"
      "--label=traefik.http.routers.${name}.rule=Host(`${host}`)"
      "--label=traefik.http.routers.${name}.entrypoints=websecure"
      "--label=traefik.http.routers.${name}.tls=true"
    ]
    ++ lib.optional (service != null) "--label=traefik.http.routers.${name}.service=${service}"
    ++ lib.optional (port != null) "--label=traefik.http.services.${name}.loadbalancer.server.port=${toString port}"
    ++ lib.optional (scheme != null) "--label=traefik.http.services.${name}.loadbalancer.server.scheme=${scheme}";
}
