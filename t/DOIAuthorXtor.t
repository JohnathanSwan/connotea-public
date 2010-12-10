use strict;
use warnings;

use Test::More;
use XML::LibXML;
use English;

BEGIN { use_ok('Bibliotech::CitationSource::DOIAuthorXtor'); };

my $pkg_under_test = 'Bibliotech::CitationSource::DOIAuthorXtor';

my $parser = XML::LibXML->new();

my $test_data = do { local $INPUT_RECORD_SEPARATOR; <DATA> };

my @tests = split qr{\nTEST_DATA_SEPARATOR\n}, $test_data;

foreach (@tests) {
    my ($description, $xml, $out) = split qr{---TESTPART\n}, $_;

    local $INPUT_RECORD_SEPARATOR = "\n";

    chomp $description;
    chomp $xml;
    chomp $out;

    # replicate the nasty hack the connotea code does
    # to get rid of namespaces !!

    $xml =~ s{<crossref_result.*?>}{<crossref_result>}s;

    my $doc = $parser->parse_string($xml);

    is(_tostring( $pkg_under_test->extract_authors($doc) ), $out, $description);
}

################### end of tests
done_testing;


sub _tostring {
    my ($authors) = @_;
    return "" unless defined $authors;
    return "" unless ref $authors;
    return "" unless ref $authors eq 'ARRAY';
    return join q{;}, @{ $authors };
}

__DATA__
A simple example
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title><contributors>
        <contributor first-author="true">
                <given_name>Jon</given_name>
                <surname>Carpetright</surname>
        </contributor>
</contributors>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Jon Carpetright
TEST_DATA_SEPARATOR
An author with a suffix
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title><contributors>
        <contributor first-author="true">
                <given_name>Jon</given_name>
                <surname>Carpetright</surname>
                <suffix>Sr.</suffix>
        </contributor>
</contributors>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Jon Carpetright Sr.
TEST_DATA_SEPARATOR
Someone with many given names
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title><contributors>
        <contributor first-author="true">
                <given_name>Foo</given_name>
                <given_name>Cooper</given_name>
                <given_name>Sooper</given_name>

                <given_name>Dooper</given_name>
                <surname>Carpetright</surname>
        </contributor>
</contributors>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Foo Cooper Sooper Dooper Carpetright
TEST_DATA_SEPARATOR
Someone with only a surname
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title><contributors>
        <contributor first-author="true">
                <surname>Thegoldenone</surname>
        </contributor>
</contributors>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Thegoldenone
TEST_DATA_SEPARATOR
Multiple  authors
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title><contributors>
        <contributor first-author="true">
                <given_name>Foo</given_name>
                <given_name>Cooper</given_name>
                <given_name>Sooper</given_name>

                <given_name>Dooper</given_name>
                <surname>Carpetright</surname>
        </contributor>
        <contributor first-author="true">
                <given_name>Bar</given_name>
                <surname>Saunders</surname>
        </contributor>
        <contributor first-author="true">
                <given_name>Baz</given_name>
                <surname>Scott</surname>
                <suffix>III</suffix>
        </contributor>
        <contributor first-author="true">
                <surname>Thegoldenone</surname>
        </contributor>

</contributors>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Foo Cooper Sooper Dooper Carpetright;Bar Saunders;Baz Scott III;Thegoldenone
TEST_DATA_SEPARATOR
No authors
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART

TEST_DATA_SEPARATOR
<contributors> but not <contributor>s
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title>
<contributors>
</contributors>

                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART

TEST_DATA_SEPARATOR
Old style author tag
---TESTPART
<?xml version = "1.0" encoding = "UTF-8"?>
<crossref_result version="2.0" xmlns="http://www.crossref.org/qrschema/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://
www.crossref.org/qrschema/2.0 http://www.crossref.org/qrschema/crossref_query_output2.0.xsd">

<query_result>
        <head>
                <email_address>connotea@nature.com</email_address>
                <doi_batch_id>DOI-B1</doi_batch_id>
        </head>
        <body>

                <query key="MyKey1" status="resolved" fl_count="0" >
                        <doi type="journal_article">10.1038/news.2010.647</doi>
                        <issn type="print">00280836</issn>
                        <issn type="electronic">14764687</issn>
                        <journal_title>Nature</journal_title>
                        <author>Fish Fever</author>
                        <year>2010</year>
                        <publication_type>full_text</publication_type>
                        <article_title>Optical wing generates lift from light</article_title>
                </query>

        </body>
</query_result>

</crossref_result>
---TESTPART
Fish Fever
