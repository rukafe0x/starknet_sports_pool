#[starknet::contract]
mod SportsPool {
    use core::byte_array::ByteArrayTrait;
    use array::{ArrayTrait, SpanTrait};
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use serde::Serde;
    use option::OptionTrait;
    use debug::PrintTrait;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        _owner: ContractAddress,
        _tournament_template: Map<u8, tournament_template>,
        _tournament_template_count: u8,
        _tournament_template_games: Map<u8, Map<u8, game_struct>>, // (tournament template id, index, game struct)
        _tournament_template_games_count: Map<u8, u8>,
        _tournament_instance: Map<u8, tournament_instance>, // (instance id, tournament instance struct)
        _tournament_instance_count: u8,
        _user_instances: Map<ContractAddress, Map<u8, u8>>, // (user address, index, registered tournament instance ids)
        _user_instances_count: Map<ContractAddress, u8>, // (user address -> tournament instance count)
        _user_instances_predictions: Map<ContractAddress, Map<u8, Map<u8, u8>>>, // (user address, tournament instance id , game number, game result)
    }

    // Struct to store tournaments games.
    #[derive(Drop, Serde, starknet::Store)]
    struct game_struct {
        team1: felt252,
        team2: felt252,
        goals1: u8,
        goals2: u8,
        datetime: u64,
        played: bool,
    }

    impl game_structClone of Clone<game_struct> {
        fn clone(self: @game_struct) -> game_struct {
            game_struct {
                team1: self.team1.clone(),
                team2: self.team2.clone(),
                goals1: self.goals1.clone(),
                goals2: self.goals2.clone(),
                datetime: self.datetime.clone(),
                played: self.played.clone(),
            }
        }
    }
    
    // Struct to store tournaments templates.
    #[derive(Drop, Serde, starknet::Store)]
    struct tournament_template {
        name: felt252,
        description: felt252,
        image_url: felt252,
        entry_fee: u256,
        prize_first_place: felt252,
        prize_second_place: felt252,
        prize_third_place: felt252,
        games_count: u8,
    }

    // Struct to store tournaments instance.
    #[derive(Drop, Serde, starknet::Store)]
    struct tournament_instance {
        instance_id: u8,
        tournament_template_id: u8,
        name: felt252,
        description: felt252,
        image_url: felt252,
        entry_fee: u256,
        prize_first_place: felt252,
        prize_second_place: felt252,
        prize_third_place: felt252,
    }

    
    #[abi(per_item)]
    #[generate_trait]
    impl SportsPoolImpl of ISportsPool {
        #[constructor]
        fn constructor(ref self: ContractState) {
            let tx_info = starknet::get_tx_info().unbox();
            self._owner.write(tx_info.account_contract_address);
        }

        #[external(v0)]
        fn get_owner(self: @ContractState) -> ContractAddress {
            self._owner.read()
        }   

        fn is_owner(self: @ContractState) -> bool {
            get_caller_address() == self._owner.read()
        }

        #[external(v0)]
        fn save_tournament_template(ref self: ContractState, tournament_template_id: u8, new_tournament_template: tournament_template) {
            assert!(self.is_owner(), "Only owner");
            self._tournament_template.entry(tournament_template_id).write(new_tournament_template);
            self._tournament_template_count.write(self._tournament_template_count.read() + 1);
        }

        #[external(v0)]
        fn get_tournament_template_count(self: @ContractState) -> u8 {
            self._tournament_template_count.read()
        }

        #[external(v0)]
        fn get_tournament_templates(self: @ContractState) -> Array<tournament_template> {
            let mut tournament_templates = ArrayTrait::new();
            for i in 0..self._tournament_template_count.read() {
                tournament_templates.append(self._tournament_template.entry(i).read());
            };
            tournament_templates
        }

        #[external(v0)]
        fn save_tournament_template_games(ref self: ContractState, tournament_template_id: u8, games: Array<game_struct>) {
            assert!(self.is_owner(), "Only owner");
            for i in 0..games.len() {
                let index :u8 = i.try_into().unwrap();
                let mut node = self._tournament_template_games.entry(tournament_template_id);
                node.entry(index).write(games[i].clone());
                self._tournament_template_games_count.entry(tournament_template_id).write(self._tournament_template_games_count.entry(tournament_template_id).read() + 1);
            };
        }

        #[external(v0)]
        fn get_tournament_template_games(self: @ContractState, tournament_template_id: u8) -> Array<game_struct> {
            let mut games = ArrayTrait::new();
            for i in 0..self._tournament_template_games_count.entry(tournament_template_id).read() {
                games.append(self._tournament_template_games.entry(tournament_template_id).entry(i).read());
            };
            games
        }

        #[external(v0)]
        fn edit_game_result(ref self: ContractState, tournament_template_id: u8, game_id: u8, goals1: u8, goals2: u8) {
            assert!(self.is_owner(), "Only owner");
            let game = self._tournament_template_games.entry(tournament_template_id).entry(game_id);
            game.goals1.write(goals1);
            game.goals2.write(goals2);
        }

        #[external(v0)]
        fn save_tournament_instance(ref self: ContractState, tournament_instance_id: u8, tournament_instance: tournament_instance) {
            self._tournament_instance.entry(tournament_instance_id).write(tournament_instance);
            self._tournament_instance_count.write(self._tournament_instance_count.read() + 1);
        }

        #[external(v0)]
        fn get_tournament_instances(self: @ContractState) -> Array<tournament_instance> {
            let mut tournament_instances = ArrayTrait::new();
            for i in 0..self._tournament_instance_count.read() {
                tournament_instances.append(self._tournament_instance.entry(i).read());
            };
            tournament_instances
        }

        #[external(v0)]
        fn register_user_instance(ref self: ContractState, tournament_instance_id: u8) {
            let user_address = get_caller_address();
            let user_instance_index = self._user_instances_count.entry(user_address).read();
            let mut user_instances = self._user_instances.entry(user_address);
            user_instances.entry(user_instance_index).write(tournament_instance_id);
            self._user_instances_count.entry(user_address).write(self._user_instances_count.entry(user_address).read() + 1);
        }

        #[external(v0)]
        fn get_user_instances(self: @ContractState) -> Array<u8> {
            let user_address = get_caller_address();
            let mut user_instances = ArrayTrait::new();
            for i in 0..self._user_instances_count.entry(user_address).read() {
                user_instances.append(self._user_instances.entry(user_address).entry(i).read());
            };
            user_instances
        }

        #[external(v0)]
        fn save_user_instance_prediction(ref self: ContractState, tournament_instance_id: u8, predictions: Array<u8>) {
            let user_address = get_caller_address();
            for i in 0..predictions.len() {
                let index :u8 = i.try_into().unwrap();
                let mut user_instances_predictions = self._user_instances_predictions.entry(user_address).entry(tournament_instance_id);
                user_instances_predictions.entry(index).write(*predictions[i]);
            };
            self._user_instances_count.entry(user_address).write(self._user_instances_count.entry(user_address).read() + 1);
        }
    }
}