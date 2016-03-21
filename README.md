# dta_sufia

Following changes need to be made to solr.xml:

Replace: <dynamicField name="*_ssort" type="alphaSort" stored="false" indexed="true" multiValued="false"/>
With:
<dynamicField name="*_ssort" type="alphaSortNoPunc" stored="false" indexed="true" multiValued="false"/>


After alphaSort:
    <!-- single token analyzed text, for sorting. Punctuation is ignored. -->
    <fieldType name="alphaSortNoPunc" class="solr.TextField" sortMissingLast="true" omitNorms="true">
      <analyzer>
        <tokenizer class="solr.KeywordTokenizerFactory"/>
        <filter class="solr.ICUFoldingFilterFactory" />
        <filter class="solr.TrimFilterFactory" />
        <filter class="solr.PatternReplaceFilterFactory"
                pattern="(^[^a-z0-9]*)|([^a-z0-9\s])" replacement="" replace="all"
        />
      </analyzer>
    </fieldType>


Note: To start sidekiq, use: bundle exec sidekiq