#!/usr/bin/perl
#
# This code was forked from the LiveJournal project owned and operated
# by Live Journal, Inc. The code has been modified and expanded by
# Dreamwidth Studios, LLC. These files were originally licensed under
# the terms of the license supplied by Live Journal, Inc, which can
# currently be found at:
#
# http://code.livejournal.org/trac/livejournal/browser/trunk/LICENSE-LiveJournal.txt
#
# In accordance with the original license, this code and all its
# modifications are provided under the GNU General Public License.
# A copy of that license can be found in the LICENSE file included as
# part of this distribution.

package LJ;

use strict;

# <LJFUNC>
# name: LJ::html_datetime
# class: component
# des: Creates date and time control HTML form elements.
# info: Parse output later with [func[LJ::html_datetime_decode]].
# args:
# des-:
# returns:
# </LJFUNC>
# It's the caller's responsibility to leave appropriate gaps if using tabindex
sub html_datetime {
    my $opts = shift;
    my $lang = $opts->{'lang'} || "EN";
    my ( $yyyy, $mm, $dd, $hh, $nn, $ss );
    my $ret;
    my $name = $opts->{name} || '';
    my $id   = $opts->{id}   || '';
    my $disabled     = $opts->{'disabled'} ? 1 : 0;
    my $tabindex     = $opts->{tabindex};
    my @tabindex_arg = ();
    @tabindex_arg = ( tabindex => $tabindex ) if defined $tabindex;

    my %extra_opts;
    foreach ( grep { !/^(name|id|disabled|seconds|notime|lang|default|tabindex)$/ } keys %$opts ) {
        $extra_opts{$_} = $opts->{$_};
    }

    if ( $opts->{'default'} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(?: (\d\d):(\d\d):(\d\d))?/ ) {
        ( $yyyy, $mm, $dd, $hh, $nn, $ss ) = (
            $1 > 0 ? $1 : "",
            $2 + 0,
            $3 > 0 ? $3 + 0 : "",
            defined $4 && $4 > 0 ? $4 : "",
            defined $5 && $5 > 0 ? $5 : "",
            defined $6 && $6 > 0 ? $6 : ""
        );
    }

    $ret .= html_select(
        {
            name     => "${name}_mm",
            id       => "${id}_mm",
            selected => sprintf( '%02d', $mm ),
            class    => 'select',
            title    => 'month',
            disabled => $disabled,
            @tabindex_arg, %extra_opts,
        },
        map { sprintf( '%02d', $_ ), LJ::Lang::month_long_ml($_) } ( 1 .. 12 )
    );
    ++$tabindex_arg[1] if defined $tabindex;
    $ret .= html_text(
        {
            name      => "${name}_dd",
            id        => "${id}_dd",
            size      => '2',
            class     => 'text',
            maxlength => '2',
            value     => $dd,
            title     => 'day',
            disabled  => $disabled,
            @tabindex_arg, %extra_opts,
        }
    );
    ++$tabindex_arg[1] if defined $tabindex;
    $ret .= html_text(
        {
            name      => "${name}_yyyy",
            id        => "${id}_yyyy",
            size      => '4',
            class     => 'text',
            maxlength => '4',
            value     => $yyyy,
            title     => 'year',
            disabled  => $disabled,
            @tabindex_arg, %extra_opts,
        }
    );
    unless ( $opts->{notime} ) {
        $ret .= ' ';
        ++$tabindex_arg[1] if defined $tabindex;
        $ret .= html_text(
            {
                name      => "${name}_hh",
                id        => "${id}_hh",
                size      => '2',
                maxlength => '2',
                value     => $hh,
                title     => 'hour',
                disabled  => $disabled,
                @tabindex_arg,
            }
        ) . ':';
        ++$tabindex_arg[1] if defined $tabindex;
        $ret .= html_text(
            {
                name      => "${name}_nn",
                id        => "${id}_nn",
                size      => '2',
                maxlength => '2',
                value     => $nn,
                title     => 'minutes',
                disabled  => $disabled,
                @tabindex_arg,
            }
        );
        if ( $opts->{seconds} ) {
            $ret .= ':';
            ++$tabindex_arg[1] if defined $tabindex;
            $ret .= html_text(
                {
                    name      => "${name}_ss",
                    id        => "${id}_ss",
                    size      => '2',
                    maxlength => '2',
                    value     => $ss,
                    title     => 'seconds',
                    disabled  => $disabled,
                    @tabindex_arg,
                }
            );
        }
    }

    return $ret;
}

# <LJFUNC>
# name: LJ::html_datetime_decode
# class: component
# des: Parses output of HTML form controls generated by [func[LJ::html_datetime]].
# info:
# args:
# des-:
# returns:
# </LJFUNC>
sub html_datetime_decode {
    my $opts = shift;
    my $hash = shift;
    my $name = $opts->{name} || '';
    return sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        $hash->{"${name}_yyyy"} || 0,
        $hash->{"${name}_mm"}   || 0,
        $hash->{"${name}_dd"}   || 0,
        $hash->{"${name}_hh"}   || 0,
        $hash->{"${name}_nn"}   || 0,
        $hash->{"${name}_ss"}   || 0
    );
}

# <LJFUNC>
# name: LJ::html_select
# class: component
# des: Creates a drop-down box or listbox HTML form element (the <select> tag).
# info:
# args: opts
# A hashref with an attribute of optgroup will be treated as a list of of value => text pairs within an optgroup
# des-opts: A hashref of options. Special options are:
#           'raw' - inserts value unescaped into select tag;
#           'noescape' - won't escape key values if set to 1;
#           'disabled' - disables the element;
#           'include_ids' - bool. If true, puts id attributes on each element in the drop-down.
#           ids are off by default, to reduce page sizes with large drop-down menus;
#           'multiple' - creates a drop-down if 0, a multi-select listbox if 1;
#           'selected' - if multiple, an arrayref of selected values; otherwise,
#           a scalar equalling the selected value;
#           All other options will be treated as HTML attribute/value pairs.
# returns: The generated HTML.
# </LJFUNC>
sub html_select {
    my $opts  = shift;
    my @items = @_;
    my $ehtml = $opts->{'noescape'} ? 0 : 1;
    my $ret;

    $ret .= "<select";
    $ret .= " $opts->{'raw'}" if $opts->{'raw'};
    $ret .= " disabled='disabled'" if $opts->{'disabled'};
    $ret .= " multiple='multiple'" if $opts->{'multiple'};
    foreach ( grep { !/^(raw|disabled|selected|noescape|multiple)$/ } keys %$opts ) {
        my $opt = $opts->{$_} || '';
        $ret .= " $_=\"" . ( $ehtml ? ehtml($opt) : $opt ) . "\"";
    }
    $ret .= ">\n";

    # build hashref from arrayref if multiple selected
    my $selref;
    $selref = { map { $_, 1 } @{ $opts->{'selected'} } }
        if $opts->{'multiple'} && ref $opts->{'selected'} eq 'ARRAY';

    my $did_sel = 0;
    while ( defined( my $value = shift @items ) ) {

        # items can be either pairs of $value, $text or a list of $it hashrefs (or a mix)
        my $it = {};
        my $text;
        if ( ref $value ) {
            $it    = $value;
            $value = $it->{value};
            $text  = $it->{text};
        }
        else {
            $text = shift @items;
        }

        if ( $it->{optgroup} ) {
            $ret .= "<optgroup label='$it->{optgroup}'>";
            $ret .=
                LJ::_html_option( $_->{value}, $_->{text}, {}, $opts, $ehtml, $selref, \$did_sel )
                foreach @{ $it->{items} || [] };
            $ret .= "</optgroup>";
        }
        else {
            $ret .= LJ::_html_option( $value, $text, $it, $opts, $ehtml, $selref, \$did_sel );
        }
    }
    $ret .= "</select>";
    return $ret;
}

sub _html_option {
    my ( $value, $text, $item, $opts, $ehtml, $selref, $did_sel ) = @_;

    my $sel = "";

    # multiple-mode or single-mode?
    if ( $selref && ( ref $selref eq 'HASH' ) && $selref->{$value}
        || defined $opts->{selected} && ( $opts->{selected} eq $value ) && !$$did_sel++ )
    {

        $sel = " selected='selected'";
    }
    $value = $ehtml ? ehtml($value) : $value;

    my $id = '';
    if ( $opts->{include_ids} && $opts->{name} ne "" && $value ne "" ) {
        $id = " id='$opts->{'name'}_$value'";
    }

    # is this individual option disabled?
    my $dis = $item->{disabled} ? " disabled='disabled' style='color: #999;'" : '';

    # are there additional data-attributes?
    my $data_attribute = '';
    my %item_data      = $item->{data} ? %{ $item->{data} } : ();
    foreach ( keys %item_data ) {
        my $val = $item_data{$_} // '';
        if ($ehtml) {
            $val = ehtml($val);
        }
        $data_attribute .= " data-$_='$val'";
    }

    return
          "<option value=\"$value\"$id$sel$dis$data_attribute>"
        . ( $ehtml ? ehtml($text) : $text )
        . "</option>\n";
}

# <LJFUNC>
# name: LJ::html_check
# class: component
# des: Creates HTML checkbox button, and radio button controls.
# info: Labels for checkboxes are through LJ::labelfy.
#       It does this safely, by not including any HTML elements in the label tag.
# args: type, opts
# des-type: Valid types are 'radio' or 'checkbox'.
# des-opts: A hashref of options. Special options are:
#           'disabled' - disables the element;
#           'selected' - if multiple, an arrayref of selected values; otherwise,
#           a scalar equalling the selected value;
#           'raw' - inserts value unescaped into select tag;
#           'noescape' - won't escape key values if set to 1;
#           'label' - label for checkbox;
# returns:
# </LJFUNC>
sub html_check {
    my $opts = shift;

    my $disabled = $opts->{'disabled'} ? " disabled='disabled'" : "";
    my $ehtml = $opts->{'noescape'} ? 0 : 1;
    my $ret;
    if ( $opts->{type} && $opts->{type} eq "radio" ) {
        $ret .= "<input type='radio'";
    }
    else {
        $ret .= "<input type='checkbox'";
    }
    if ( $opts->{'selected'} ) { $ret .= " checked='checked'"; }
    if ( $opts->{'raw'} )      { $ret .= " $opts->{'raw'}"; }
    foreach ( grep { !/^(disabled|type|selected|raw|noescape|label)$/ } keys %$opts ) {
        $ret .= " $_=\"" . ( $ehtml ? ehtml( $opts->{$_} ) : $opts->{$_} ) . "\"";
    }
    $ret .= "$disabled />";
    my $e_label = ( $ehtml ? ehtml( $opts->{'label'} ) : $opts->{'label'} );
    $e_label = LJ::labelfy( $opts->{id}, $e_label );
    $ret .= $e_label if $opts->{'label'};
    return $ret;
}

# given a string and an id, return the string
# in a label, respecting HTML
sub labelfy {
    my ( $id, $text, $class ) = @_;
    $id   = '' unless defined $id;
    $text = '' unless defined $text;

    $class = LJ::ehtml( $class || "" );
    $class = qq{class="$class"} if $class;

    $text =~ s!
        ^([^<]+)
        !
        <label for="$id" $class>
            $1
        </label>
        !x;

    return $text;
}

# <LJFUNC>
# name: LJ::html_text
# class: component
# des: Creates a text input field, for single-line input.
# info: Allows 'type' =&gt; 'password' flag.
# args:
# des-:
# returns: The generated HTML.
# </LJFUNC>
sub html_text {
    my $opts = shift;

    my $disabled = $opts->{'disabled'} ? " disabled='disabled'" : "";
    my $ehtml    = $opts->{'noescape'} ? 0                      : 1;
    my $type     = 'text';
    $type = $opts->{type}
        if $opts->{type}
        && ( $opts->{type} eq 'password'
        || $opts->{type} eq 'search' );
    my $ret = '';
    $ret .= "<div class=\"password-wrapper\">" if $opts->{type} eq 'password';
    $ret .= "<input type=\"$type\"";
    foreach ( grep { !/^(type|disabled|raw|noescape)$/ } keys %$opts ) {
        my $val = defined $opts->{$_} ? $opts->{$_} : '';
        $ret .= " $_=\"" . ( $ehtml ? LJ::ehtml($val) : $val ) . "\"";
    }
    if ( $opts->{'raw'} ) { $ret .= " $opts->{'raw'}"; }
    $ret .= "$disabled />";
    if ($type == "password") {
        $ret .= <<EOF;
            <span class\"toggle-show\">
                <button
                    type=\"button\"
                    class=\"toggle-show-link\"
                    onclick=\"let curstate=this.parentElement.previousSibling.getAttribute('type');this.parentElement.previousSibling.setAttribute('type', curstate == 'password' ? 'text' : 'password');this.textContent=(curstate == 'password' ? 'Hide password?' : 'Show password?');\"
                >
                    Show Password
                </button>
            </span>
EOF
    }
    $ret .= "</div>" if $opts->{type} eq 'password';
    return $ret;
}

# <LJFUNC>
# name: LJ::html_textarea
# class: component
# des: Creates a text box for multi-line input (the <textarea> tag).
# info:
# args:
# des-:
# returns: The generated HTML.
# </LJFUNC>
sub html_textarea {
    my $opts = $_[0];

    my $disabled = $opts->{disabled} ? " disabled='disabled'" : "";
    my $ehtml = $opts->{noescape} ? 0 : 1;
    my $value = $opts->{value} || '';
    $value = ehtml($value) if $ehtml;

    my $ret = "<textarea";
    foreach ( grep { !/^(disabled|raw|value|noescape)$/ } keys %$opts ) {
        $ret .= " $_=\"" . ( $ehtml ? ehtml( $opts->{$_} ) : $opts->{$_} ) . "\"";
    }
    $ret .= " $opts->{raw}" if $opts->{raw};
    $ret .= "$disabled>$value</textarea>";
    return $ret;
}

# <LJFUNC>
# name: LJ::html_color
# class: component
# des: A text field with attached color preview and button to choose a color.
# info: Depends on the client-side Color Picker.
# args: opts
# des-opts: Valid options are: 'onchange' argument, which happens when
#           color picker button is clicked, or when focus is changed to text box;
#           'disabled'; and 'raw' , for unescaped input.
# returns:
# </LJFUNC>
sub html_color {
    my $opts = shift;

    my $htmlname = ehtml( $opts->{'name'} );
    my $des      = ehtml( $opts->{'des'} ) || "Pick a Color";
    my $ret;

    # 'onchange' argument happens when color picker button is clicked,
    # or when focus is changed to text box

    $ret .= html_text(
        {
            'size'      => 8,
            'maxlength' => 7,
            'name'      => $htmlname,
            'id'        => $htmlname,
            'onfocus'   => $opts->{'onchange'},
            'disabled'  => $opts->{'disabled'},
            'value'     => $opts->{'default'},
            'noescape'  => 1,
            'raw'       => $opts->{'raw'} . " data-coloris",
        }
    );

    # A little help for the non-JavaScript folks
    $ret .= "<noscript> (#<var>rr</var><var>gg</var><var>bb</var>)</noscript>";

    return $ret;
}

# <LJFUNC>
# name: LJ::html_hidden
# class: component
# des: Makes the HTML for a hidden form element.
# args: name, val, opts
# des-name: Name of form element (will be HTML escaped).
# des-val: Value of form element (will be HTML escaped).
# des-opts: Can optionally take arguments that are hashrefs
#           and extract name/value/other standard keys from that. Can also be
#           mixed with the older style key/value array calling format.
# returns: HTML
# </LJFUNC>
sub html_hidden {
    my $ret;

    while (@_) {
        my $name = shift;
        my $val;
        my $ehtml = 1;
        my $extra = '';
        if ( ref $name eq 'HASH' ) {
            my $opts = $name;

            $val  = $opts->{value};
            $name = $opts->{name};

            $ehtml = $opts->{'noescape'} ? 0 : 1;
            foreach ( grep { !/^(name|value|raw|noescape)$/ } keys %$opts ) {
                $extra .= " $_=\"" . ( $ehtml ? ehtml( $opts->{$_} ) : $opts->{$_} ) . "\"";
            }

            $extra .= " $opts->{'raw'}" if $opts->{'raw'};

        }
        else {
            $val = shift;
        }

        $ret .= "<input type='hidden'";

        # allow override of these in 'raw'
        $ret .= " name=\"" .  ( $ehtml ? ehtml($name) : $name ) . "\"" if $name;
        $ret .= " value=\"" . ( $ehtml ? ehtml($val)  : $val ) . "\""  if defined $val;
        $ret .= "$extra />";
    }
    return $ret;
}

# <LJFUNC>
# name: LJ::html_submit
# class: component
# des: Makes the HTML for a submit button.
# info: If only one argument is given it is
#       assumed LJ::html_submit(undef, 'value') was meant.
# args: name, val, opts?, type
# des-name: Name of form element (will be HTML escaped).
# des-val: Value of form element, and label of button (will be HTML escaped).
# des-opts: Optional hashref of additional tag attributes.
#           A hashref of options. Special options are:
#           'raw' - inserts value unescaped into select tag;
#           'disabled' - disables the element;
#           'noescape' - won't escape key values if set to 1;
# des-type: Optional. Value format is type =&gt; (submit|reset). Defaults to submit.
# returns: HTML
# </LJFUNC>
sub html_submit {
    my ( $name, $val, $opts ) = @_;

    # if one argument, assume (undef, $val)
    if ( @_ == 1 ) {
        $val  = $name;
        $name = undef;
    }

    my ( $eopts, $disabled, $raw ) = ( '', '', '' );
    my $type = 'submit';

    my $ehtml;
    if ( $opts && ref $opts eq 'HASH' ) {
        $disabled = " disabled='disabled'" if $opts->{'disabled'};
        $raw      = " $opts->{'raw'}"      if $opts->{'raw'};
        $type     = 'reset'                if $opts->{type} && $opts->{type} eq 'reset';

        $ehtml = $opts->{'noescape'} ? 0 : 1;
        foreach ( grep { !/^(raw|disabled|noescape|type)$/ } keys %$opts ) {
            $eopts .= " $_=\"" . ( $ehtml ? ehtml( $opts->{$_} ) : $opts->{$_} ) . "\"";
        }
    }
    my $ret = "<input type='$type'";

    # allow override of these in 'raw'
    $ret .= " name=\"" .  ( $ehtml ? ehtml($name) : $name ) . "\"" if $name;
    $ret .= " value=\"" . ( $ehtml ? ehtml($val)  : $val ) . "\""  if defined $val;
    $ret .= "$eopts$raw$disabled />";
    return $ret;
}

1;
