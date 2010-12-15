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

my $base_xpath = '/doi_records/doi_record/crossref/journal/journal_article';

foreach (@tests) {
    my ($description, $xml, $out) = split qr{---TESTPART\n}, $_;

    local $INPUT_RECORD_SEPARATOR = "\n";

    chomp $description;
    chomp $xml;
    chomp $out;

    my $doc = $parser->parse_string($xml);

    is(_tostring( $pkg_under_test->extract_authors($doc, $base_xpath) ),
       $out,
       $description,
    );
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
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
     <person_name sequence="first" contributor_role="author">
      <given_name>Jon</given_name>
      <surname>Carpetright</surname>
     </person_name>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART
Jon Carpetright
TEST_DATA_SEPARATOR
An author with a suffix
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
     <person_name sequence="first" contributor_role="author">
      <given_name>Jon</given_name>
      <surname>Carpetright</surname>
      <suffix>Sr.</suffix>
     </person_name>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART
Jon Carpetright Sr.
TEST_DATA_SEPARATOR
Someone with many given names
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
     <person_name sequence="first" contributor_role="author">
      <given_name>Foo Cooper Sooper Dooper</given_name>
      <surname>Carpetright</surname>
     </person_name>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART
Foo Cooper Sooper Dooper Carpetright
TEST_DATA_SEPARATOR
Someone with only a surname
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
     <person_name sequence="first" contributor_role="author">
      <surname>Thegoldenone</surname>
     </person_name>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART
Thegoldenone
TEST_DATA_SEPARATOR
Multiple authors
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
     <person_name sequence="first" contributor_role="author">
      <given_name>Foo Cooper Sooper Dooper</given_name>
      <surname>Carpetright</surname>
     </person_name>
     <person_name sequence="first" contributor_role="author">
      <given_name>Bar</given_name>
      <surname>Saunders</surname>
     </person_name>
     <person_name sequence="first" contributor_role="author">
      <given_name>Baz</given_name>
      <surname>Scott</surname>
      <suffix>III</suffix>
     </person_name>
     <person_name sequence="first" contributor_role="author">
      <surname>Thegoldenone</surname>
     </person_name>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>---TESTPART
Foo Cooper Sooper Dooper Carpetright;Bar Saunders;Baz Scott III;Thegoldenone
TEST_DATA_SEPARATOR
No authors
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART

TEST_DATA_SEPARATOR
<contributors> but not <contributor>s
---TESTPART
<doi_records>
<doi_record version="1.1">
 <crossref>
  <journal>
   <journal_metadata>
    <full_title>Cell Death and Differentiation</full_title>
    <abbrev_title>Cell Death Differ</abbrev_title>
    <issn media_type="print">1350-9047</issn>
    <issn media_type="electronic">1476-5403</issn>
   </journal_metadata>
   <journal_issue>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
   </journal_issue>
   <journal_article publication_type="full_text">
    <titles>
     <title>Galectin-1 sensitizes carcinoma cells to anoikis via the fibronectin receptor α5β1-integrin</title>
    </titles>
    <contributors>
    </contributors>
    <publication_date media_type="online">
     <month>11</month>
     <day>26</day>
     <year>2010</year>
    </publication_date>
    <publisher_item>
     <identifier id_type="other">cdd2010148</identifier>
    </publisher_item>
    <doi_data>
     <doi>10.1038/cdd.2010.148</doi>
     <timestamp>20101126105302</timestamp>
     <resource>http://www.nature.com/doifinder/10.1038/cdd.2010.148</resource>
    </doi_data>
    <citation_list>
     <citation key="cdd2010148-bib1">
      <doi>10.1007/s10555-005-5134-3</doi>
     </citation>
    </citation_list>
   </journal_article>
  </journal>
 </crossref>
</doi_record>
</doi_records>
---TESTPART

