class HomosaurusV2Controller < ApplicationController
  before_action :verify_homosaurus
  include DtaStaticBuilder

  before_action :get_latest_content

  def index
    #@terms = HomosaurusV2.all.sort_by { |term| term.preferred_label }
    #@terms = HomosaurusV2.all
    @terms = HomosaurusV2.find_with_conditions("*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first }
  end

  def show
    @homosaurus = HomosaurusV2.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def new
    @homosaurus = HomosaurusV2.new
    term_query = HomosaurusV2.find_with_conditions("*:*", rows: '10000', fl: 'id,identifier_ssi' )
    term_query = term_query.sort_by { |term| term["identifier_ssi"] }
    @all_terms = []
    term_query.each { |term| @all_terms << [term["identifier_ssi"], term["id"]] }

  end

  def create
    if !params[:homosaurus][:identifier].match(/^[a-zA-Z_\-]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to new_homosauru_path, notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else

      id = 'homosaurus/terms/v2/' + params[:homosaurus][:identifier]

      @homosaurus = HomosaurusV2.new(id)

      if params[:homosaurus][:broader_ids].present?
        params[:homosaurus][:broader_ids].each do |broader|
          if broader.present?
            broader_object = HomosaurusV2.find(broader)
            @homosaurus.broader = @homosaurus.broader + [broader_object]
            broader_object.narrower = broader_object.narrower + [@homosaurus]
            broader_object.save
          end
        end
      end

      if params[:homosaurus][:narrower_ids].present?
        params[:homosaurus][:narrower_ids].each do |narrower|
          if narrower.present?
            narrower_object = HomosaurusV2.find(narrower)
            @homosaurus.narrower = @homosaurus.narrower + [narrower_object]
            narrower_object.broader = narrower_object.broader + [@homosaurus]
            narrower_object.save
          end

        end
      end

      if params[:homosaurus][:related_ids].present?
        params[:homosaurus][:related_ids].each do |related|
          if related.present?
            related_object = HomosaurusV2.find(related)
            @homosaurus.related = @homosaurus.related + [related_object]
            related_object.related = related_object.related + [@homosaurus]
            related_object.save
          end

        end
      end

      @homosaurus.issued = RDF::Literal::Date.new(Time.now)
      @homosaurus.modified = RDF::Literal::Date.new(Time.now)

      @homosaurus.update(homosaurus_params)

      if @homosaurus.save
        redirect_to homosauru_path(:id => @homosaurus.id)
      else
        redirect_to new_homosauru_path
      end
    end
  end

  def edit
    @homosaurus = HomosaurusV2.find(params[:id])
    term_query = HomosaurusV2.find_with_conditions("*:*", rows: '100000', fl: 'id,identifier_ssi' )
    @all_terms = []
    term_query.each { |term|
      if params[:id] != term["id"]
        @all_terms << [term["identifier_ssi"], term["id"]]
      end
    }
  end

  def update
    if !params[:homosaurus][:identifier].match(/^[a-zA-Z_\-]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to homosauru_path(:id => params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else

      @homosaurus = HomosaurusV2.find(params[:id])

      #FIXME: Only do this if changed...
      @homosaurus.broader.each do |broader|
        broader.narrower.delete(@homosaurus)
        broader.save
      end


      @homosaurus.narrower.each do |narrower|
        narrower.broader.delete(@homosaurus)
        narrower.save
      end


      @homosaurus.related.each do |related|
        related.related.delete(@homosaurus)
        related.save
      end
      @homosaurus.reload

      @homosaurus.broader = []
      @homosaurus.narrower = []
      @homosaurus.related = []

      id = 'homosaurus/terms/v2/' + params[:homosaurus][:identifier]

      if @homosaurus.id != id
=begin
      @homosaurus.broader.each do |broader|
        broader.narrower = broader.narrower - [@homosaurus]
        broader.save
      end

      @homosaurus.narrower.each do |narrower|
        narrower.broader = narrower.broader - [@homosaurus]
        narrower.save
      end

      @homosaurus.related.each do |related|
        related.related = related.related - [@homosaurus]
        related.save
      end
=end

        @homosaurus.delete

        @homosaurus = HomosaurusV2.new(id)
        @homosaurus.issued = RDF::Literal::Date.new(Time.now)
      end

      if params[:homosaurus][:broader_ids].present?
        params[:homosaurus][:broader_ids].each do |broader|
          if broader.present?
            broader_object = HomosaurusV2.find(broader)
            @homosaurus.broader = @homosaurus.broader + [broader_object]
            broader_object.narrower = broader_object.narrower + [@homosaurus]
            broader_object.save
          end
        end
      end

      if params[:homosaurus][:narrower_ids].present?
        params[:homosaurus][:narrower_ids].each do |narrower|
          if narrower.present?
            narrower_object = HomosaurusV2.find(narrower)
            @homosaurus.narrower = @homosaurus.narrower + [narrower_object]
            narrower_object.broader = narrower_object.broader + [@homosaurus]
            narrower_object.save
          end

        end
      end

      if params[:homosaurus][:related_ids].present?
        params[:homosaurus][:related_ids].each do |related|
          if related.present?
            related_object = HomosaurusV2.find(related)
            @homosaurus.related = @homosaurus.related + [related_object]
            related_object.related = related_object.related + [@homosaurus]
            related_object.save
          end

        end
      end

      @homosaurus.modified = RDF::Literal::Date.new(Time.now)

      @homosaurus.update(homosaurus_params)

      if @homosaurus.save
        #flash[:success] = "HomosaurusV2 term was updated!"
        redirect_to homosaurus_v2_path(:id => @homosaurus.id), notice: "HomosaurusV2 term was updated!"
      else
        redirect_to homosaurus_v2_path(:id => @homosaurus.id), notice: "Failure! Term was not updated."
      end
    end
  end

  def destroy

    @homosaurus = HomosaurusV2.find(params[:id])

    @homosaurus.broader.each do |broader|
      broader.narrower.delete(@homosaurus)
      broader.save
    end


    @homosaurus.narrower.each do |narrower|
      narrower.broader.delete(@homosaurus)
      narrower.save
    end


    @homosaurus.related.each do |related|
      related.related.delete(@homosaurus)
      related.save
    end
    @homosaurus.reload

    @homosaurus.broader = []
    @homosaurus.narrower = []
    @homosaurus.related = []

    @homosaurus.delete
    HomosaurusV2.eradicate(params[:id])
    #flash[:success] = "HomosaurusV2 Term deleted"
    redirect_to homosaurus_v2_index_path, notice: "HomosaurusV2 term was deleted!"
  end


  def homosaurus_params
       params.require(:homosaurus).permit(:identifier, :prefLabel, :description, :exactMatch, :closeMatch, altLabel: [])
  end
end