package XML::Liberal::Error;
use strict;

use base qw( Class::Accessor );

__PACKAGE__->mk_ro_accessors(qw( message line column location ));

sub summary {
    my $self = shift;

    my $line   = $self->line;
    my $column = $self->column;
    my $location = defined $line && defined $column ? "$line:$column"
                 : defined $line                    ? $line
                 :                                    'unknown location';
    return join ' at position ', $self->message, $location
}

1;
__END__

=head1 INTERNALS

This information is for people hacking on XML::Liberal; it's not public API
documentation.

There are three sorts of class that cooperate to do the liberal parsing: the
error class, a driver, and a remedy class.

Instances of the error class, C<XML::Liberal::Error>, encapsulate the
details of an error detected by an XML parser.  They have fields C<message>,
C<line>, C<column>, and C<location> extracted from a parser error;
C<location> is the position within the string of the location described by
the error.  They also have a method C<summary>, which combines those pieces
of information in a human-readable way).

A driver knows how to extract line/column/location/message from exceptions
generated by a particular XML parser.  It is a subclass of C<XML::Liberal>;
the only current driver is C<XML::Liberal::LibXML>, which handles parser
exceptions thrown by C<XML::LibXML>.  The driver subclass must implement a
method C<extract_error>, which takes an exception argument and a reference
to the XML source text, and returns a suitable instance of
C<XML::Liberal::Error>.

Each remedy has a class method C<apply> which takes three arguments, a
driver instance, an error instance, and a reference to the XML source text.
It either (a) does nothing and returns false (to indicate that it doesn't
know how to fix this problem, so other remedies should be given the
opportunity to do so); or (b) modifies the text referenced by its third
argument and returns true (whereupon the error is considered as fixed as
possible, so no other remedy will be invoked for this error).

The driver base class C<parse_string> method first tries to use the
underlying XML parser to parse the document.  If that works, all is well;
otherwise, it attempts to apply remedies to fix the problem that arose.  It
considers each remedy class in turn; as soon as one remedy says it's handled
this error, it tries to parse again.  If no remedies claim to have handled
the error, it gives up.

=cut