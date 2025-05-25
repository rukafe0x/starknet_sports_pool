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
    use starknet::eth_address::EthAddress;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::contract_address::contract_address_const;
    use starknet::get_contract_address;

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
        _user_instances_predictions_list: Map<ContractAddress, Map<u8, u8>>, // (user address, index, tournament instance id)
        _user_instances_predictions_list_count: Map<ContractAddress, u8>, // (user address, predictions count)
        _user_instances_user_list: Map <u8, Map<u8, ContractAddress>>, // (tournament instance id, index, user address)
        _user_instances_user_list_count: Map<u8, u8>, // (tournament instance id, user count)
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

    #[derive(Drop, Serde, starknet::Store, Copy)]
    struct UserPoints {
        user: ContractAddress,
        points: u8,
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
            //update games_count for the tournament template
            let curr_tournament_template = self._tournament_template.entry(tournament_template_id).read();
            let updated_tournament_template = tournament_template {
                name: curr_tournament_template.name.clone(),
                description: curr_tournament_template.description.clone(),
                image_url: curr_tournament_template.image_url.clone(),
                entry_fee: curr_tournament_template.entry_fee.clone(),
                prize_first_place: curr_tournament_template.prize_first_place.clone(),
                prize_second_place: curr_tournament_template.prize_second_place.clone(),
                prize_third_place: curr_tournament_template.prize_third_place.clone(),
                games_count: games.len().try_into().unwrap(),
            };
            self._tournament_template.entry(tournament_template_id).write(updated_tournament_template);
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
        fn edit_game_result(ref self: ContractState, tournament_template_id: u8, game_id: u8, goals1: u8, goals2: u8, played: bool) {
            assert!(self.is_owner(), "Only owner");
            let game = self._tournament_template_games.entry(tournament_template_id).entry(game_id);
            game.goals1.write(goals1);
            game.goals2.write(goals2);
            game.played.write(played);
        }

        #[external(v0)]
        fn save_tournament_instance(ref self: ContractState, tournament_instance: tournament_instance) {
            // get instance_id from counter and update the instance_id in the tournament_instance structure received
            let instance_id = self._tournament_instance_count.read();
            let mut updated_tournament_instance = tournament_instance {
                instance_id: instance_id,
                tournament_template_id: tournament_instance.tournament_template_id.clone(),
                name: tournament_instance.name.clone(),
                description: tournament_instance.description.clone(),
                image_url: tournament_instance.image_url.clone(),
                entry_fee: tournament_instance.entry_fee.clone(),
                prize_first_place: tournament_instance.prize_first_place.clone(),
                prize_second_place: tournament_instance.prize_second_place.clone(),
                prize_third_place: tournament_instance.prize_third_place.clone(),
            };
            self._tournament_instance.entry(instance_id).write(updated_tournament_instance);
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
        fn get_user_instances(self: @ContractState, user_address: ContractAddress) -> Array<u8> {
            let mut user_instances = ArrayTrait::new();
            for i in 0..self._user_instances_count.entry(user_address).read() {
                user_instances.append(self._user_instances.entry(user_address).entry(i).read());
            };
            user_instances
        }

        #[external(v0)]
        fn save_user_instance_prediction(ref self: ContractState, tournament_instance_id: u8, predictions: Array<u8>) {
            let user_address = get_caller_address();
            
            // Get the entry fee from the tournament instance
            let entry_fee = self._tournament_instance.entry(tournament_instance_id).entry_fee.read();
            
            // Transfer the entry fee from the user to the contract
            let strk_token_dispatcher = ERC20ABIDispatcher {
                contract_address: contract_address_const::<
                    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d,
                >() // STRK Contract Address
            };
            
            strk_token_dispatcher.transferFrom(user_address, get_contract_address(), entry_fee);

            // Rest of the existing function code
            for i in 0..predictions.len() {
                let index :u8 = i.try_into().unwrap();
                let mut user_instances_predictions = self._user_instances_predictions.entry(user_address).entry(tournament_instance_id);
                user_instances_predictions.entry(index).write(*predictions[i]);
            };
            self._user_instances_count.entry(user_address).write(self._user_instances_count.entry(user_address).read() + 1);
            
            let mut user_instance_index = self._user_instances_user_list_count.entry(tournament_instance_id).read();
            self._user_instances_user_list.entry(tournament_instance_id).entry(user_instance_index).write(user_address);
            self._user_instances_user_list_count.entry(tournament_instance_id).write(user_instance_index + 1);

            let user_instance_index = self._user_instances_predictions_list_count.entry(user_address).read();
            let mut user_instances_predictions_list = self._user_instances_predictions_list.entry(user_address);
            user_instances_predictions_list.entry(user_instance_index).write(tournament_instance_id);
            self._user_instances_predictions_list_count.entry(user_address).write(user_instance_index + 1);
        }

        #[external(v0)]
        fn get_user_instance_predictions(self: @ContractState, user_address: ContractAddress, tournament_instance_id: u8) -> Array<u8> {
            // Get tournament_template_id from the instance
            let tournament_template_id = self._tournament_instance.entry(tournament_instance_id).tournament_template_id.read();
            // count games for that template
            let games_count = self._tournament_template_games_count.entry(tournament_template_id).read();
            
            let mut predictions = ArrayTrait::new();
            for i in 0..games_count {
                predictions.append(self._user_instances_predictions.entry(user_address).entry(tournament_instance_id).entry(i).read());
            };
            predictions
        }

        #[external(v0)]
        fn get_user_instance_predictions_list(self: @ContractState, user_address: ContractAddress) -> Array<u8> {
            let mut user_instances_predictions_list = self._user_instances_predictions_list.entry(user_address);
            let mut instances_predictions_list = ArrayTrait::new();
            for i in 0..self._user_instances_predictions_list_count.entry(user_address).read() {
                instances_predictions_list.append(user_instances_predictions_list.entry(i).read());
            };
            instances_predictions_list
        }
        
        // get leadeaboard from an instance
        // for each game, we compare the prediction with the actual result
        // we sum the points for each user
        // 3 points for each game if the prediction is correct
        // 0 point for each game if the prediction is wrong
        #[external(v0)]
        fn get_instance_leaderboard(self: @ContractState, tournament_instance_id: u8) -> Array<(ContractAddress, u8)> {
            // Get tournament_template_id from the instance
            let tournament_template_id = self._tournament_instance.entry(tournament_instance_id).tournament_template_id.read();
            // create an array with all results of the games for that template
            let games = self._tournament_template_games.entry(tournament_template_id);
            let mut results:Array<(u8,bool)> = ArrayTrait::new();
            let games_count = self._tournament_template_games_count.entry(tournament_template_id).read();
            for i in 0..games_count {
                let mut result:u8 = 0;
                let mut played:bool = games.entry(i).played.read();
                if games.entry(i).goals1.read() > games.entry(i).goals2.read() {
                    result = 1;
                } else if games.entry(i).goals1.read() < games.entry(i).goals2.read() {
                    result = 2;
                }
                results.append((result, played));
            };

            // create an array (tuple)of user address and points for each user.
            let mut leaderboard = ArrayTrait::new();
            // iterate over the user list of the instance
            for i in 0..self._user_instances_user_list_count.entry(tournament_instance_id).read() {
                //iterate over the predictions of the user and totalize points comparing against the results array
                let user_address = self._user_instances_user_list.entry(tournament_instance_id).entry(i).read();
                let predictions = self._user_instances_predictions.entry(user_address).entry(tournament_instance_id);
                let mut points = 0;
                for j in 0..games_count {
                    let mut result = 0;
                    let predicted_result:u8 = predictions.entry(j).read();
                    let (correct_result, played):(u8, bool) = *results.at(j.into());
                    if played {
                        if predicted_result == correct_result {
                            result = 3;
                        }
                    }
                    points = points + result;
                };
                leaderboard.append((user_address, points));
            };
            leaderboard
        }

        #[external(v0)]
        fn pay_price(ref self: ContractState, tournament_instance_id: u8) {
            // Get tournament_template_id from the instance
            let tournament_template_id = self._tournament_instance.entry(tournament_instance_id).tournament_template_id.read();
            // create an array with all results of the games for that template
            let games = self._tournament_template_games.entry(tournament_template_id);
            let mut results:Array<(u8,bool)> = ArrayTrait::new();
            let games_count = self._tournament_template_games_count.entry(tournament_template_id).read();
            for i in 0..games_count {
                let mut result:u8 = 0;
                let mut played:bool = games.entry(i).played.read();
                if games.entry(i).goals1.read() > games.entry(i).goals2.read() {
                    result = 1;
                } else if games.entry(i).goals1.read() < games.entry(i).goals2.read() {
                    result = 2;
                }
                results.append((result, played));
            };

            // create an array (tuple)of user address and points for each user.
            let mut leaderboard:Array<UserPoints> = ArrayTrait::new();
            // iterate over the user list of the instance
            for i in 0..self._user_instances_user_list_count.entry(tournament_instance_id).read() {
                //iterate over the predictions of the user and totalize points comparing against the results array
                let user_address = self._user_instances_user_list.entry(tournament_instance_id).entry(i).read();
                let predictions = self._user_instances_predictions.entry(user_address).entry(tournament_instance_id);
                let mut points = 0;
                for j in 0..games_count {
                    let mut result = 0;
                    let predicted_result:u8 = predictions.entry(j).read();
                    let (correct_result, played):(u8, bool) = *results.at(j.into());
                    if played {
                        if predicted_result == correct_result {
                            result = 3;
                        }
                    }
                    points = points + result;
                };
                leaderboard.append(UserPoints { user: user_address, points: points });
            };
            

            // now get the top 3 leaders of the leaderboard array
            let n = leaderboard.len();

            // Initialize our top 3 leaders.
            // We'll use individual variables to simulate a small sorted list.
            // Initialize with default values (0 points, 0 user)
            let mut leader1 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 1st leader
            let mut leader2 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 2nd leader
            let mut leader3 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 3rd leader

            let mut i = 0;
            loop {
                if i >= n {
                    break;
                }

                let current_user_points = *leaderboard.at(i);

                // Compare with leader1 (highest points)
                if current_user_points.points > leader1.points {
                    // current_user_points becomes new leader1, push others down
                    leader3 = leader2;
                    leader2 = leader1;
                    leader1 = current_user_points;
                } else if current_user_points.points > leader2.points {
                    // current_user_points becomes new leader2, push leader2 down to leader3
                    leader3 = leader2;
                    leader2 = current_user_points;
                } else if current_user_points.points > leader3.points {
                    // current_user_points becomes new leader3
                    leader3 = current_user_points;
                } else if current_user_points.points == leader1.points {
                    // Handle tie-breaker for leader1
                    if current_user_points.user < leader1.user {
                        leader3 = leader2;
                        leader2 = leader1;
                        leader1 = current_user_points;
                    }
                } else if current_user_points.points == leader2.points {
                    // Handle tie-breaker for leader2
                    if current_user_points.user < leader2.user {
                        leader3 = leader2;
                        leader2 = current_user_points;
                    }
                } else if current_user_points.points == leader3.points {
                    // Handle tie-breaker for leader3
                    if current_user_points.user < leader3.user {
                        leader3 = current_user_points;
                    }
                }
                // If points are less than or equal to leader3, and no tie-breaker applies,
                // then current_user_points is not in the top 3.

                i += 1;
            };

            // if msg sender is in top 3, transfer the price of the tournament instance to the msg sender
            let msg_sender = get_caller_address();
            if leader1.user == msg_sender || leader2.user == msg_sender || leader3.user == msg_sender {
                // get the price of the tournament instance
                // the price is the price_N_place as a porcentage of the total particpants * entry fee
                let entry_fee = self._tournament_instance.entry(tournament_instance_id).entry_fee.read();
                let total_participants = self._user_instances_user_list_count.entry(tournament_instance_id).read();
                // Then price will depend on the position of the msg sender
                let mut price: u256 = 0;
                if leader1.user == msg_sender {
                    let price_first_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_first_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_first_place / 100;
                } else if leader2.user == msg_sender {
                    let price_second_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_second_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_second_place / 100;
                } else if leader3.user == msg_sender {
                    let price_third_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_third_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_third_place / 100;
                }
                // transfer the price to the msg sender
                let strk_token_dispatcher = ERC20ABIDispatcher {
                    contract_address: contract_address_const::<
                        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d,
                    >() // STRK Contract Address
                };
                strk_token_dispatcher.transfer(msg_sender, price);
            }
        }

        #[external(v0)]
        fn check_price(ref self: ContractState, tournament_instance_id: u8) -> u256 {
            // Get tournament_template_id from the instance
            let tournament_template_id = self._tournament_instance.entry(tournament_instance_id).tournament_template_id.read();
            // create an array with all results of the games for that template
            let games = self._tournament_template_games.entry(tournament_template_id);
            let mut results:Array<(u8,bool)> = ArrayTrait::new();
            let games_count = self._tournament_template_games_count.entry(tournament_template_id).read();
            for i in 0..games_count {
                let mut result:u8 = 0;
                let mut played:bool = games.entry(i).played.read();
                if games.entry(i).goals1.read() > games.entry(i).goals2.read() {
                    result = 1;
                } else if games.entry(i).goals1.read() < games.entry(i).goals2.read() {
                    result = 2;
                }
                results.append((result, played));
            };

            // create an array (tuple)of user address and points for each user.
            let mut leaderboard:Array<UserPoints> = ArrayTrait::new();
            // iterate over the user list of the instance
            for i in 0..self._user_instances_user_list_count.entry(tournament_instance_id).read() {
                //iterate over the predictions of the user and totalize points comparing against the results array
                let user_address = self._user_instances_user_list.entry(tournament_instance_id).entry(i).read();
                let predictions = self._user_instances_predictions.entry(user_address).entry(tournament_instance_id);
                let mut points = 0;
                for j in 0..games_count {
                    let mut result = 0;
                    let predicted_result:u8 = predictions.entry(j).read();
                    let (correct_result, played):(u8, bool) = *results.at(j.into());
                    if played {
                        if predicted_result == correct_result {
                            result = 3;
                        }
                    }
                    points = points + result;
                };
                leaderboard.append(UserPoints { user: user_address, points: points });
            };
            

            // now get the top 3 leaders of the leaderboard array
            let n = leaderboard.len();

            // Initialize our top 3 leaders.
            // We'll use individual variables to simulate a small sorted list.
            // Initialize with default values (0 points, 0 user)
            let mut leader1 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 1st leader
            let mut leader2 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 2nd leader
            let mut leader3 = UserPoints { user: contract_address_const::<0x0000000000000000000000000000000000000000000000000000000000000000>(), points: 0 }; // Will hold the 3rd leader

            let mut i = 0;
            loop {
                if i >= n {
                    break;
                }

                let current_user_points = *leaderboard.at(i);

                // Compare with leader1 (highest points)
                if current_user_points.points > leader1.points {
                    // current_user_points becomes new leader1, push others down
                    leader3 = leader2;
                    leader2 = leader1;
                    leader1 = current_user_points;
                } else if current_user_points.points > leader2.points {
                    // current_user_points becomes new leader2, push leader2 down to leader3
                    leader3 = leader2;
                    leader2 = current_user_points;
                } else if current_user_points.points > leader3.points {
                    // current_user_points becomes new leader3
                    leader3 = current_user_points;
                } else if current_user_points.points == leader1.points {
                    // Handle tie-breaker for leader1
                    if current_user_points.user < leader1.user {
                        leader3 = leader2;
                        leader2 = leader1;
                        leader1 = current_user_points;
                    }
                } else if current_user_points.points == leader2.points {
                    // Handle tie-breaker for leader2
                    if current_user_points.user < leader2.user {
                        leader3 = leader2;
                        leader2 = current_user_points;
                    }
                } else if current_user_points.points == leader3.points {
                    // Handle tie-breaker for leader3
                    if current_user_points.user < leader3.user {
                        leader3 = current_user_points;
                    }
                }
                // If points are less than or equal to leader3, and no tie-breaker applies,
                // then current_user_points is not in the top 3.

                i += 1;
            };

            // if msg sender is in top 3, transfer the price of the tournament instance to the msg sender
            let msg_sender = get_caller_address();
            let mut price: u256 = 0;
            if leader1.user == msg_sender || leader2.user == msg_sender || leader3.user == msg_sender {
                // get the price of the tournament instance
                // the price is the price_N_place as a porcentage of the total particpants * entry fee
                let entry_fee = self._tournament_instance.entry(tournament_instance_id).entry_fee.read();
                let total_participants = self._user_instances_user_list_count.entry(tournament_instance_id).read();
                // Then price will depend on the position of the msg sender
                if leader1.user == msg_sender {
                    let price_first_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_first_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_first_place / 100;
                } else if leader2.user == msg_sender {
                    let price_second_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_second_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_second_place / 100;
                } else if leader3.user == msg_sender {
                    let price_third_place: u256 = self._tournament_instance.entry(tournament_instance_id).prize_third_place.read().into();
                    price = (entry_fee * total_participants.into()) * price_third_place / 100;
                }
            }
            price
        }
    }
}