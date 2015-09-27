use Moops;

# PODCLASSNAME

# ABSTRACT: Pluggable role (MooX::Role::Pluggable overriden)

role MarpaX::Languages::XML::Role::Pluggable {
  use MooX::Role::Logger;
  use MooX::Role::Pluggable;
  use MooX::Role::Pluggable::Constants;

  # VERSION

  # AUTHORITY

  #
  # The differences with original MooX::Role::Pluggable are:
  # - no @extra parameters
  # - none of our handlers are supposed to croak, nor return
  #   a bad constant, i.e. no eval and no __plugin_process_chk.
  #   For the later, I rewriten it to use MooX::Role::Logger in a
  #   new method __my_plugin_process_chk, never called.

  around _pluggable_process {
    my ($type, $event) = splice(@_, 0, 2);

    my $prefix = $self->__pluggable_opts->{ev_prefix};
    substr($event, 0, length($prefix), '') if index($event, $prefix) == 0;

    my $meth = $self->__pluggable_opts->{types}->{$type} .'_'. $event;

    my ($retval, $self_ret) = EAT_NONE;
    local $@;
    if      ( $self->can($meth) ) {
      # Dispatch to ourself
      $self_ret = $self->$meth($self, @_)
      # __my_plugin_process_chk($self, $self, $meth, $self_ret);
    } elsif ( $self->can('_default') ) {
      # Dispatch to _default
      $self_ret = $self->_default($self, $meth, @_)
      #__my_plugin_process_chk($self, $self, '_default', $self_ret);
    }

    if      (! defined $self_ret) {
      # No-op.
    } elsif ( $self_ret == EAT_PLUGIN ) {
      # Don't plugin-process, just return EAT_NONE.
      # (Higher levels like Emitter can still pick this up.)
      return $retval
    } elsif ( $self_ret == EAT_CLIENT ) {
      # Plugin process, but return EAT_ALL after.
      $retval = EAT_ALL
    } elsif ( $self_ret == EAT_ALL ) {
      return EAT_ALL
    }

    my $handle_ref = $self->__pluggable_loaded->{HANDLE};
    my $plug_ret;
  PLUG: for my $thisplug (
                          grep {;
                                exists $handle_ref->{$_}->{$type}->{$event}
                                  || exists $handle_ref->{$_}->{$type}->{all}
                                  && $self != $_
                                } @{ $self->__pluggable_pipeline } )  {
      undef $plug_ret;
      # Using by_ref is nicer, but the method call is too much overhead.
      my $this_alias = $self->__pluggable_loaded->{OBJ}->{$thisplug};

      if      ( $thisplug->can($meth) ) {
              $plug_ret = $thisplug->$meth($self, @_)
        # __my_plugin_process_chk($self, $thisplug, $meth, $plug_ret, $this_alias);
      } elsif ( $thisplug->can('_default') ) {
              $plug_ret = $thisplug->_default($self, $meth, @_)
        # __my_plugin_process_chk($self, $thisplug, '_default', $plug_ret, $this_alias);
      }

      if      (! defined $plug_ret) {
        # No-op.
      } elsif ($plug_ret == EAT_PLUGIN) {
        # Stop plugin-processing.
        # Return EAT_ALL if we previously had a EAT_CLIENT
        # Return EAT_NONE otherwise
        return $retval
      } elsif ($plug_ret == EAT_CLIENT) {
        # Set a pending EAT_ALL.
        # If another plugin in the pipeline returns EAT_PLUGIN,
        # we'll tell higher layers like Emitter to EAT_ALL
        $retval = EAT_ALL
      } elsif ($plug_ret == EAT_ALL) {
        return EAT_ALL
      }

    }  # PLUG

    $retval
  }

  method __my_plugin_process_chk {
    if ($@) {
      chomp $@;
      my ($obj, $meth, undef, $src) = @_;

      my $e_src = defined $src ? "plugin '$src'" : 'self' ;
      my $err = "$meth call on $e_src failed: $@";

      $self->_logger->warnf($err);

      $self->_pluggable_event(
                              $self->__pluggable_opts->{ev_prefix} . "plugin_error",
                              $err,
                              $obj,
                              $e_src
                             );

      return
    } elsif (! defined $_[2] ||
      ( $_[2] != EAT_NONE   && $_[2] != EAT_ALL &&
        $_[2] != EAT_CLIENT && $_[2] != EAT_PLUGIN ) ) {

      my ($obj, $meth, undef, $src) = @_;

      my $e_src = defined $src ? "plugin '$src'" : 'self' ;
      my $err = "$meth call on $e_src did not return a valid EAT_ constant";

      $self->_logger->warnf($err);

      $self->_pluggable_event(
                              $self->__pluggable_opts->{ev_prefix} . "plugin_error",
                              $err,
                              $obj,
                              $e_src
                             );

      return
    }
  }

  around __plug_pipe_handle_err {
    my ($err, $plugin, $alias) = @_;

    $self->_logger->warnf($err);

    $self->_pluggable_event(
                            $self->__pluggable_opts->{ev_prefix} . "plugin_error",
                            $err,
                            $plugin,
                            $alias
                           );
  }

  with 'MooX::Role::Logger';
  with 'MooX::Role::Pluggable';
}

1;
