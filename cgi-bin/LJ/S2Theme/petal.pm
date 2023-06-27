package LJ::S2Theme::petal;
use base qw( LJ::S2Theme );
use strict;

sub layouts {
    (
        "2l" => "two-columns-left",
        "2r" => "two-columns-right"
    )
}
sub layout_prop { "layout_type" }

sub page_props {
    my $self = shift;
    my @props =
        qw(color_accent);
    return $self->_append_props( "page_props", @props );
}

1;
