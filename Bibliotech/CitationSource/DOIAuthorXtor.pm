use strict;
use warnings;

# split from the bulky DOI module for ease of testing...

package Bibliotech::CitationSource::DOIAuthorXtor;

use Bibliotech::Log4perl qw{logger};

=head1 Bibliotech::CitationSource::DOIAuthorExtractor
       - extract authors from DOI metadata

=head1 SYNOPSIS

my $authors_arrayref = $PKG->extract_authors($crossref_xml_obj);

=head1 DESCRIPTION

Provides the extract_authors method.

Accepts the LibXML document of the crossref XML

Returns an arrayref of strings that will be parsed by connotea to
populate the authors field.

I know, the crossref XML contains useful structure of the author name,
but how to explain that to connotea in the present structure is
beyond me in the time I have to do this. --JS 2010-12-10

=head1 METHODS

=head2 $PKG->extract_authors( $crossref_xml_obj )

Extract an arrayref of strings of author names from the crossref
metadata response XML (provided as a LibXML document object).

Returns nothing if it can't find anything.

=cut 
sub extract_authors {
    my ($self, $crossref_xml_doc, $xpath_to_base) = @_;

    return unless $crossref_xml_doc && $crossref_xml_doc->can('findnodes');

    # There seem to be 2 models available in crossref.
    # the contributors models seems to be preferred, so try it first.

    my $authors = $self->_crossref_contributors_tag_content(
        $crossref_xml_doc, $xpath_to_base
    );

    return $authors;
}

# extract authors from the 'contributors' model
sub _crossref_contributors_tag_content {
    my ($self, $crossref_xml_doc, $xpath_to_base) = @_;

    my $contrib_xpath = $xpath_to_base . '/contributors';
    logger->debug("looking for contributors at: $contrib_xpath");

    my ($contrib_node) = $crossref_xml_doc->findnodes($contrib_xpath);
    logger->debug("contrib node not found") unless defined $contrib_node;

    return unless defined $contrib_node;

    my @contributors = $contrib_node->findnodes('person_name');
    logger->debug("found contribs: " . scalar @contributors);

    return unless @contributors;
    my @authors;

    foreach my $contributor ( @contributors ) {
        logger->debug("processing contributor: $contributor");
        # make a name string in the form "given_name* surname suffix*"
        # as specified in the crossref query response 2.0 xsd

        # Although surname, givennames*, suffix* would seem less ambiguious
        # Bibliotech does a better job of understanding first name first format
        # a nicer way to do this would be to create a special Author subclass
        # and populate the fields according to this XML instead of asking
        # Bibliotech to parse it. I don't have the budget to do that now.
  
        # Also, Crossref seems to only return one author at a time and the
        # author's name is not always marked up correctly / consistently
        # in the crossref result anyway.

        # get surname first because it's mandatory.
        my $author_name = $contributor->findvalue('surname');


        my $given_names =
            join q{ },
            map { $_->findvalue(q{.}) } $contributor->findnodes('given_name');

        $author_name = join q{ }, $given_names, $author_name
            if $given_names;

        $author_name = join q{ }, $author_name, $contributor->findvalue('suffix')
            if $contributor->findnodes('suffix');

        push @authors, $author_name;
    }

    return \@authors;
}

1;
__END__
