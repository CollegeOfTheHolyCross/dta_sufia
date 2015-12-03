class InstitutionsController < ApplicationController
  before_action :verify_admin

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @institutions = Institution.find_with_conditions("*:*", rows: '1000', fl: 'id,name_ssim' )
    @institutions = @institutions.sort_by { |term| term["name_ssim"].first }
  end

  def show
    @institution = Institution.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def new
    @institution = Institution.new
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }

  end

  def create
    @institution = Institution.new(institution_params)

    current_time = Time.now
    @institution.date_created =   current_time.strftime("%Y-%m-%d")
    @institution.permissions_attributes = [{type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]

=begin
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
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id)
    else
      redirect_to new_institution_path
    end
  end

  def edit
    @institution = Institution.find(params[:id])
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }
  end

  def update
    @institution = Institution.find(params[:id])
    @institution.update(institution_params)

=begin
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
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id), notice: "Institution was updated!"
    else
      redirect_to new_institution_path
    end
  end


  def institution_params
    params.require(:institution).permit(:name, :description, :contact_person, :address, :email, :phone, :institution_url)
  end
end