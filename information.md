Screen Layout (and basic context)

Icons / Logo
    logo = logo.png
    gold = gold_icon.png
    silver = silver_icon.png
    platinum = platinum_icon.png
    Imperial Bullion = imp_icon.png
    Gold Secure = gs_icon.png
    Gold Bullion Australia = gba_icon.png
Header
    Menu
    Logo & Title
    Current Gain/Loss $
    Todays Best Buyback Price for 1oz Gold (retailer), 1oz Silver (retailer), 1oz Platinum (retailer)
    Todays Best Sell Price for 1oz Gold (retailer), 1oz Silver (retailer), 1oz Platinum (retailer)

Menu
    Home
    My Holdings
        Portfolio Valuation
        List of active Holdings
            Default TAB
            Filterable and sortable on all columns
        List Sold Holdings 
            Selectable TAB
            Filterable and sortable on all columns
        Add Holding
        Sell Holding 
        Edit Holding (for selected Holding)
            Map to Profile button
            Delete Holding 
    Product Profiles
        List Product Profiles
            Sortable on all columns
            Add Product Profile 
                PROBLEM - Unable to add Product Profile 
	        Edit Product Profile 
                Delete Product Profile 
    Live Prices
        List of Live Prices
            Filterable and sortable on all columns
            Get Live Prices 
                Get GBA Live Prices
                Get GS Live Prices
                Get IMP Live Prices
                Manually add Live Price
                    BUG: Needs to be moved to the top with the other buttons
            Edit Live Price 
                Delete Live Price
                Map to Product Profile
    Product Listings
        List of Product Listings
            Filterable and sortable of all columns
            Get Product Listings 
                Get GBA Product Listings
                Get GS Product Listings
                Get IMP Product Listings
                Manually Add Product Listing 
	        Edit Product Listing 
                Map to Profile 
                Delete Product Listing 
    Spot Prices
        List of Spot Prices 
            Table view = date | time | Provider | Global / Spot |  Gold | Silver | Platinum
            Filterable and sortable on all columns
            Get Spot Prices 
                Get GBA Spot Price
                Get GS Spot Price
                Get IMP Spot Price
                Get Global Spot Price
            Edit Spot Price 
                Map to Profile 
                Delete Spot Price 
            Configure Global Spot Price API
                Choose Global Spot Price Provider
                Configure Global Spot Price provider

    Retailers
        List of Retailers
            Filterable and sortable of all columns
            Add Retailer 
            Edit Retailer 
                Delete Retailer 
            Retailer Scraper Settings
                Add Retailer Scraper Setting
                Edit Retailer Scraper Setting
                    Delete Retailer Scraper Setting
    Analytics (coming soon)
    Settings
        Profile
        Global Spot API Config
            Add Global Spot API Config
            Edit Global Spot API Config
                Delete Global Spot API Config
Footer
    Live dd/mm/yyyy hh:mm   |   Listings dd/mm/yyyy hh:mm   |   Spot Prices: dd/mm/yyyy hh:mm (BUG: not formatted correctly, got Spot Price and Global Spot Price)


Flutter Architecture (Folder structure)
|--	lib/
|   |--	core/
|   |   |--	constants/
|   |   |   |--	app_constants.dart
|   |   |   |--	scraper_constants.dart
|   |   |--	theme/
|   |   |   |--	app_theme.dart
|   |   |--	utils/
|   |   |   |--	weight_converter.dart
|   |   |   |--	metal_color_helper.dart
|--	│
|   |--	features/
|   |   |--	authentication/
|   |   |   |--	presentation
|   |   |   |   |--	screens
|   |   |   |   |  |--	auth_screen.dart
|   |   |   |   |  |--	auth_wrapper.dart
|   |   |   |   |--	widgets	
|   |   |--	home/
|   |   |   |--	presentation/
|   |   |   |   |--	providers/
|   |   |   |   |  |--	home_providers.dart
|   |   |   |   |--	screens/
|   |   |   |   |  |--	home_screen.dart
|   |   |   |   |--	widgets/
|   |   |   |   |  |--	header_widget.dart
|   |   |   |   |  |--	best_prices_widget.dart
|   |   |   |   |  |--	gain_loss_widget.dart
|   |--	holdings/
|   |   |--	data/
|   |   |   |--	models/
|   |   |   |   |--	holding_model.dart
|   |   |   |--	repositories/
|   |   |   |   |--	holdings_repository.dart
|   |   |--	presentation/
|   |   |   |--	providers/
|   |   |   |   |--	holdings_providers.dart
|   |   |   |--	screens/
|   |   |   |   |--	holdings_screen.dart
|   |   |   |   |--	add_edit_holding_screen.dart
|   |   |   |   |--	holding_detail_screen.dart
|   |   |   |--	widgets/
|   |   |   |   |--	portfolio_valuation_card.dart
|   |--	product_profiles/
|   |   |--	 data/
|   |   |   |--	 models/
|   |   |   |   |--	 product_profile_model.dart
|   |   |   |--	 repositories/
|   |   |   |   |--	 product_profiles_repository.dart
|   |   |--	 presentation/
|   |   |   |--	 providers/
|   |   |   |   |--	 product_profiles_providers.dart
|   |   |   |--	 screens/
|   |   |   |   |--	 product_profiles_screen.dart
|   |   |   |   |--	 add_edit_product_profile_screen.dart
|   |   |   |--	 widgets/
|   |--	live_prices/
|   |   |--	 data/
|   |   |   |--	 models/
|   |   |   |   |--	live_price_model.dart
|   |   |   |--	 repositories/
|   |   |   |   |--	 live_prices_repository.dart
|   |   |   |--	 services/
|   |   |   |   |--	 base_scraper_service.dart
|   |   |   |   |--	 gba_live_price_service.dart
|   |   |   |   |--	 gs_live_price_service.dart
|   |   |   |   |--	 imp_live_price_service.dart
|   |   |--	 presentation/
|   |   |   |--	 providers/
|   |   |   |   |--	 live_prices_providers.dart
|   |   |   |--	 screens/
|   |   |   |   |--	live_prices_screen.dart
|   |   |   |   |--	 manual_live_price_entry_screen.dart
|   |   |   |   |--	 live_price_mapping_screen.dart
|   |   |   |--	 widgets/
|   |--	product_listings/
|   |   |   |--	 data/
|   |   |   |   |--	 models/
|   |   |   |   |  |--	 product_listing_model.dart
|   |   |   |   |--	 repositories/
|   |   |   |   |  |--	 product_listings_repository.dart
|   |   |   |   |--	 services/
|   |   |   |   |  |--	gba_product_listing_service.dart
|   |   |   |   |  |--	gs_product_listing_service.dart
|   |   |   |   |  |--	imp_product_listing_service.dart
|   |   |   |--	presentation/
|   |   |   |   |--	providers/
|   |   |   |   |  |--	product_listings_providers.dart
|   |   |   |   |--	screens/
|   |   |   |   |  |--	product_listings_screen.dart
|   |   |   |   |--	widgets/
|   |--	spot_prices/
|   |   |--	data/
|   |   |   |--	models/
|   |   |   |   |--	local_spot_price_model.dart
|   |   |   |   |--	global_spot_price_model.dart
|   |   |   |--	repositories/
|   |   |   |   |--	spot_prices_repository.dart
|   |   |   |--	services/
|   |   |   |   |--	global_spot_price_service.dart
|   |   |   |   |--	gba_spot_price_service.dart
|   |   |   |   |--	gs_spot_Price_service.dart
|   |   |   |   |--	imp_spot_price_service.dart
|   |   |--	presentation/
|   |   |   |--	providers/
|   |   |   |   |--	spot_prices_providers.dart
|   |   |   |--	screens/
|   |   |   |   |--	spot_prices_screen.dart
|   |   |   |--	widgets/
|   |--	retailers/
|   |   |--	data/
|   |   |   |--	models/
|   |   |   |   |--	retailer_model.dart
|   |   |   |   |--	 retailer_scraper_setting_model.dart
|   |   |   |--	repositories/
|   |   |   |   |--	retailers_repository.dart
|   |   |--	presentation/
|   |   |   |--	providers/
|   |   |   |   |--	retailers_providers.dart
|   |   |   |--	screens/
|   |   |   |   |--	retailers_screen.dart
|   |   |   |   |--	add_edit_retailer_screen.dart
|   |   |   |   |--	add_edit_scraper_setting_screen.dart
|   |   |   |--	 widgets/
|   |--	analytics/
|   |   |--	presentation/
|   |   |   |--	screens/
|   |   |   |   |--	analytics_screen.dart
|   |--	settings/
|   |   |--	presentation/
|   |   |   |--	screens/
|   |   |   |   |--	settings_screen.dart
|--	main.dart
