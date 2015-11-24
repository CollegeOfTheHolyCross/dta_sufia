class HomosaurusController < ApplicationController
  before_action :verify_admin

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @terms = Homosaurus.find_with_conditions("*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms.sort_by { |term| term["prefLabel_tesim"].first }
  end

  def show
    @homosaurus = Homosaurus.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def new
    @homosaurus = Homosaurus.new
    term_query = Homosaurus.find_with_conditions("*:*", rows: '10000', fl: 'id,identifier_ssi' )
    @all_terms = []
    term_query.each { |term| @all_terms << [term["identifier_ssi"], term["id"]] }

  end

  def create
    if !params[:homosaurus][:identifier].match(/^[a-zA-Z_\-]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to new_homosauru_path, notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else

      id = 'homosaurus/terms/' + params[:homosaurus][:identifier]

      @homosaurus = Homosaurus.new(id)

      if params[:homosaurus][:broader_ids].present?
        params[:homosaurus][:broader_ids].each do |broader|
          if broader.present?
            broader_object = Homosaurus.find(broader)
            @homosaurus.broader = @homosaurus.broader + [broader_object]
            broader_object.narrower = broader_object.narrower + [@homosaurus]
            broader_object.save
          end
        end
      end

      if params[:homosaurus][:narrower_ids].present?
        params[:homosaurus][:narrower_ids].each do |narrower|
          if narrower.present?
            narrower_object = Homosaurus.find(narrower)
            @homosaurus.narrower = @homosaurus.narrower + [narrower_object]
            narrower_object.broader = narrower_object.broader + [@homosaurus]
            narrower_object.save
          end

        end
      end

      if params[:homosaurus][:related_ids].present?
        params[:homosaurus][:related_ids].each do |related|
          if related.present?
            related_object = Homosaurus.find(related)
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
    @homosaurus = Homosaurus.find(params[:id])
    term_query = Homosaurus.find_with_conditions("*:*", rows: '100000', fl: 'id,identifier_ssi' )
    @all_terms = []
    term_query.each { |term|
      if params[:id] != term["id"]
        @all_terms << [term["identifier_ssi"], term["id"]]
      end
    }
  end

  def update
    if !params[:homosaurus][:identifier].match(/^[a-zA-Z_\-]+$/) || params[:homosaurus][:identifier].match(/ /)
      redirect_to homosauru_path(:id => 'homosaurus/terms/' + params[:homosaurus][:identifier]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else

      @homosaurus = Homosaurus.find(params[:id])

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

      id = 'homosaurus/terms/' + params[:homosaurus][:identifier]

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

        @homosaurus = Homosaurus.new(id)
        @homosaurus.issued = RDF::Literal::Date.new(Time.now)
      end

      if params[:homosaurus][:broader_ids].present?
        params[:homosaurus][:broader_ids].each do |broader|
          if broader.present?
            broader_object = Homosaurus.find(broader)
            @homosaurus.broader = @homosaurus.broader + [broader_object]
            broader_object.narrower = broader_object.narrower + [@homosaurus]
            broader_object.save
          end
        end
      end

      if params[:homosaurus][:narrower_ids].present?
        params[:homosaurus][:narrower_ids].each do |narrower|
          if narrower.present?
            narrower_object = Homosaurus.find(narrower)
            @homosaurus.narrower = @homosaurus.narrower + [narrower_object]
            narrower_object.broader = narrower_object.broader + [@homosaurus]
            narrower_object.save
          end

        end
      end

      if params[:homosaurus][:related_ids].present?
        params[:homosaurus][:related_ids].each do |related|
          if related.present?
            related_object = Homosaurus.find(related)
            @homosaurus.related = @homosaurus.related + [related_object]
            related_object.related = related_object.related + [@homosaurus]
            related_object.save
          end

        end
      end

      @homosaurus.modified = RDF::Literal::Date.new(Time.now)

      @homosaurus.update(homosaurus_params)

      if @homosaurus.save
        #flash[:success] = "Homosaurus term was updated!"
        redirect_to homosauru_path(:id => @homosaurus.id), notice: "Homosaurus term was updated!"
      else
        redirect_to homosauru_path(:id => @homosaurus.id), notice: "Failure! Term was not updated."
      end
    end
  end

  def destroy

    @homosaurus = Homosaurus.find(params[:id])

    @homosaurus.broader.each do |broader|
      broader.narrower.delete(@homosaurus)
      broader.save
    end


    @homosaurus.narrower.each do |narrower|
      narrower.broader.delete(@homosaurus)
      narrower.save
    end


    @homosaurus.related.each do |related|
      related.delete(@homosaurus)
      related.save
    end
    @homosaurus.reload

    @homosaurus.broader = []
    @homosaurus.narrower = []
    @homosaurus.related = []

    @homosaurus.delete
    #flash[:success] = "Homosaurus Term deleted"
    redirect_to homosaurus_path, notice: "Homosaurus term was deleted!"
  end


  def homosaurus_params
       params.require(:homosaurus).permit(:identifier, :prefLabel, :description, altLabel: [])
  end
end